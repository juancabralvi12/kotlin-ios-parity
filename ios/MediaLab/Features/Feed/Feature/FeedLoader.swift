import Foundation

public protocol FeedLoader {

    typealias Result = Swift.Result<[FeedItem], Error>

    func load(completion: @escaping (Result) -> Void)
}