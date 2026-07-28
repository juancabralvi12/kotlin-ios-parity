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

    func load(completion: @escaping (FeedLoader.Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }

            switch result {
            case let .success((data, url)):
                completion(FeedItemsMapper.map(data, from: url))
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
}
