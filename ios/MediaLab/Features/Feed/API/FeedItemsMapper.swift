//
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

class FeedItemsMapper {
    private static let OK_200 = 200

    private init() {}

    private struct Item: Decodable {
        private let id: String
        private let title: String?
        private let summary: String?
        private let imageURL: URL

        var item: FeedItem {
            return FeedItem(id: id,
                             title: title ?? "",
                             summary: summary ?? "",
                             url: imageURL)
        }
    }

    private struct FeedImageResponse: Decodable {
        private let items: [Item]

        var feed: [FeedItem] {
            return items.map(\.item)
        }
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == FeedItemsMapper.OK_200, let root = try? JSONDecoder().decode(FeedImageResponse.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }

        return root.feed
    }
}
