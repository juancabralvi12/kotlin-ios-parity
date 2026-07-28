
import Foundation 

protocol HTTPClient {
    typealias Result = Swift.Result<(Data, URLResponse), Error>

    func get(from url: URL, completion: @escaping (Result) -> Void)

}
