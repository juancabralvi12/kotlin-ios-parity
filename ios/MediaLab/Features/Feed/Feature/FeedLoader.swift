import Foundation

protocol FeedLoader: Sendable {
    func load() async throws -> [FeedItem]
}
