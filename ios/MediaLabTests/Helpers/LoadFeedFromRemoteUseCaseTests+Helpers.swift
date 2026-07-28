//
//  Copyright © Essential Developer. All rights reserved.
//

@preconcurrency import XCTest
@testable import MediaLab

extension LoadFeedFromRemoteUseCaseTests {
	func expect(_ sut: RemoteFeedLoader, toCompleteWith expectedResult: Result<[FeedItem], RemoteFeedLoader.Error>, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) async {
		action()

		do {
			let receivedItems = try await sut.load()

			guard case let .success(expectedItems) = expectedResult else {
				return XCTFail("Expected \(expectedResult), got success with \(receivedItems) instead", file: file, line: line)
			}

			XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
		} catch {
			guard case let .failure(expectedError) = expectedResult,
				  let receivedError = error as? RemoteFeedLoader.Error else {
				return XCTFail("Expected \(expectedResult), got failure with \(error) instead", file: file, line: line)
			}

			XCTAssertEqual(receivedError, expectedError, file: file, line: line)
		}
	}
}
