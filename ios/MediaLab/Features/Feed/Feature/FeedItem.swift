import Foundation

struct FeedItem: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let summary: String
    let url: URL
}
