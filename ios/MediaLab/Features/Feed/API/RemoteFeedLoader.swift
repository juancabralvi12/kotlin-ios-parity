import Foundation 

final class RemoteFeedLoader {
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

    func load(completion: @escaping (FeedLoader.Result) -> Void) {
        
    }
}
