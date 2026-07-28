//
//  Copyright © Essential Developer. All rights reserved.
//

@preconcurrency import XCTest
@testable import MediaLab

@MainActor
class LoadFeedFromRemoteUseCaseTests: XCTestCase {
	//  ***********************
	//
	//  [DO NOT DELETE THIS COMMENT]
	//
	//  Follow the TDD process:
	//
	//  1. Uncomment and run one test at a time (run tests with CMD+U).
	//  2. Do the minimum to make the test pass and commit.
	//  3. Refactor if needed and commit again.
	//
	//  Repeat this process until all tests are passing.
	//
	//  ***********************

	func test_init_doesNotRequestDataFromURL() {
		let (_, client) = makeSUT()

		XCTAssertTrue(client.requestedURLs.isEmpty)
	}

	func test_loadTwice_requestsDataFromURLTwice() async {
		let url = URL(string: "https://a-given-url.com")!
		let (sut, client) = makeSUT(url: url)

		_ = try? await sut.load()
		_ = try? await sut.load()

		XCTAssertEqual(client.requestedURLs, [url, url])
	}

	func test_load_deliversConnectivityErrorOnClientError() async {
		let (sut, client) = makeSUT()

		await expect(sut, toCompleteWith: .failure(.connectivity), when: {
			let clientError = NSError(domain: "Test", code: 0)
			client.complete(with: clientError)
		})
	}

	func test_load_deliversInvalidDataErrorOnNon200HTTPResponse() async {
		let (sut, client) = makeSUT()

		let samples = [199, 201, 300, 400, 500]

		for code in samples {
			await expect(sut, toCompleteWith: .failure(.invalidData), when: {
				let json = makeItemsJSON([])
				client.complete(withStatusCode: code, data: json)
			})
		}
	}

	func test_load_deliversInvalidDataErrorOn200HTTPResponseWithInvalidJSON() async {
		let (sut, client) = makeSUT()

		await expect(sut, toCompleteWith: .failure(.invalidData), when: {
			let invalidJSON = Data("invalid json".utf8)
			client.complete(withStatusCode: 200, data: invalidJSON)
		})
	}

	func test_load_deliversInvalidDataErrorOn200HTTPResponseWithPartiallyValidJSONItems() async {
		let (sut, client) = makeSUT()

		let validItem = makeItem(
			id: "anystring",
			imageURL: URL(string: "http://another-url.com")!
		).json

		let invalidItem = ["invalid": "item"]

		let items = [validItem, invalidItem]

		await expect(sut, toCompleteWith: .failure(.invalidData), when: {
			let json = makeItemsJSON(items)
			client.complete(withStatusCode: 200, data: json)
		})
	}

	func test_load_deliversSuccessWithNoItemsOn200HTTPResponseWithEmptyJSONList() async {
		let (sut, client) = makeSUT()

		await expect(sut, toCompleteWith: .success([]), when: {
			let emptyListJSON = makeItemsJSON([])
			client.complete(withStatusCode: 200, data: emptyListJSON)
		})
	}

	func test_load_deliversSuccessWithItemsOn200HTTPResponseWithJSONItems() async {
		let (sut, client) = makeSUT()

		let item1 = makeItem(
			id: "anystring",
			imageURL: URL(string: "http://a-url.com")!)

		let item2 = makeItem(
			id: "anystring",
			title: "",
			summary: "",
			imageURL: URL(string: "http://another-url.com")!)

		let items = [item1.model, item2.model]

		await expect(sut, toCompleteWith: .success(items), when: {
			let json = makeItemsJSON([item1.json, item2.json])
			client.complete(withStatusCode: 200, data: json)
		})
	}

	// MARK: - Helpers

	private func makeSUT(url: URL = URL(string: "https://a-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
		let client = HTTPClientSpy()
		let sut = RemoteFeedLoader(url: url, client: client)
		trackForMemoryLeaks(sut, file: file, line: line)
		trackForMemoryLeaks(client, file: file, line: line)
		return (sut, client)
	}

	private func makeItem(id: String, title: String? = nil, summary: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
		let item = FeedItem(id: id, title: title ?? "", summary: summary ?? "", url: imageURL)

		let json = [
			"id": id,
			"title": title ?? nil,
            "summary": summary ?? nil,
			"imageURL": imageURL.absoluteString
		].compactMapValues { $0 }

		return (item, json)
	}

	private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
		let json = ["items": items]
		return try! JSONSerialization.data(withJSONObject: json)
	}
}
