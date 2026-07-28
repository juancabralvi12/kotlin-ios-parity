//
//  Copyright © Essential Developer. All rights reserved.
//

@preconcurrency import XCTest
import Foundation
@testable import MediaLab

final class HTTPClientSpy: HTTPClient, @unchecked Sendable {
	private struct StubError: Error {}

	private let lock = NSLock()
	private var _requestedURLs = [URL]()
	private var result: Swift.Result<(Data, HTTPURLResponse), Error> = .failure(StubError())

	var requestedURLs: [URL] {
		withLock { _requestedURLs }
	}

	func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
		let stubbedResult = withLock {
			_requestedURLs.append(url)
			return result
		}

		return try stubbedResult.get()
	}

	func complete(with error: Error) {
		withLock {
			result = .failure(error)
		}
	}

	func complete(withStatusCode code: Int, data: Data) {
		let response = HTTPURLResponse(
			url: URL(string: "https://a-url.com")!,
			statusCode: code,
			httpVersion: nil,
			headerFields: nil
		)!

		withLock {
			result = .success((data, response))
		}
	}

	private func withLock<T>(_ action: () -> T) -> T {
		lock.lock()
		defer { lock.unlock() }
		return action()
	}
}
