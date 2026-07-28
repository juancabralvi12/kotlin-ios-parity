import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private final class CompletionBox: @unchecked Sendable {
        private let completion: (HTTPClient.Result) -> Void

        init(_ completion: @escaping (HTTPClient.Result) -> Void) {
            self.completion = completion
        }

        func callAsFunction(_ result: HTTPClient.Result) {
            completion(result)
        }
    }

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    private struct UnexpectedValuesRepresentation: Error {}

    public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        let completion = CompletionBox(completion)

        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}
