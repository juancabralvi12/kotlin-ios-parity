import Foundation 

final class RemoteFeedLoader: FeedLoader {
    private let url: URL
    private let client: HTTPClient

    enum Error: Swift.Error, Equatable {
        case connectivity
        case invalidData
    }

    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    func load() async throws -> [FeedItem] {
        let data: Data
        let response: HTTPURLResponse

        do {
            (data, response) = try await client.get(from: url)
        } catch {
            throw Error.connectivity
        }

        return try FeedItemsMapper.map(data, from: response)
    }
}
