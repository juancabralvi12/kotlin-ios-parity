
import Foundation 

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, URLResponse), Error>

    public func get(url: String, completion: @escaping (Result) -> Void)

}