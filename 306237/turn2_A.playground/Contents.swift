
import Foundation
// Define a protocol for HTTPRequest
protocol HTTPRequest {
    // Associatedtype to represent the expected response type
    associatedtype Response: Decodable
    
    // The URL for the HTTP request
    var url: URL { get }
    
    // The HTTP method for the request
    var method: String { get }
    
    // The HTTP headers for the request
    var headers: [String: String] { get }
    
    // The body data for the request (optional)
    var body: Data? { get }
    
    // Function to build and return the HTTPRequest object
    static func build() -> Self
    
    // Function to transform the JSON data to the expected response struct
    func transformResponse(_ data: Data) -> Response?
}

// Implement a default extension for the HTTPRequest protocol
extension HTTPRequest {
    var headers: [String: String] {
        return [:]
    }
    
    var body: Data? {
        return nil
    }
    
    func transformResponse(_ data: Data) -> Response? {
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            print("Error transforming response: \(error)")
            return nil
        }
    }
}
// Example of a specific HTTPRequest implementation
struct UserRequest: HTTPRequest {
    typealias Response = User
    
    let url: URL
    let method = "GET"
    
    static func build() -> UserRequest {
        let baseURL = URL(string: "https://api.example.com")!
        let userID = "123"
        let url = baseURL.appendingPathComponent("/users/\(userID)")
        return UserRequest(url: url)
    }
}

// Example of another specific HTTPRequest implementation
struct PostsRequest: HTTPRequest {
    typealias Response = [Post]
    
    let url: URL
    let method = "GET"
    
    static func build() -> PostsRequest {
        let baseURL = URL(string: "https://api.example.com")!
        let url = baseURL.appendingPathComponent("/posts")
        return PostsRequest(url: url)
    }
}
// Define a struct to represent the expected response data for UserRequest
struct User: Decodable {
    let id: Int
    let name: String
    let email: String
}

// Define a struct to represent the expected response data for PostsRequest
struct Post: Decodable {
    let id: Int
    let title: String
    let body: String
}

import Foundation

// Define a custom error enum to handle different types of errors that might occur during the network request
enum NetworkError: Error {
    case urlError(URLError)
    case clientError(HTTPURLResponse, Data?)
    case serverError(HTTPURLResponse, Data?)
    case decodingError(Error)
    case unknownError
}

// Modified NetworkLayer class to handle errors properly
class NetworkLayer {
    func performRequest<T: HTTPRequest>(_ request: T, completion: @escaping (Result<T.Response, NetworkError>) -> Void) {
        let task = URLSession.shared.dataTask(with: request.url) { data, response, error in
            if let error = error as? URLError {
                completion(.failure(.urlError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.unknownError))
                return
            }

            switch httpResponse.statusCode {
            case 200..<300:
                guard let data = data else {
                    completion(.failure(.unknownError))
                    return
                }

                if let response = request.transformResponse(data) {
                    completion(.success(response))
                } else {
                    completion(.failure(.decodingError(NSError(domain: "NetworkLayer", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to transform response"]))))
                }
            case 400..<500:
                completion(.failure(.clientError(httpResponse, data)))
            default:
                completion(.failure(.serverError(httpResponse, data)))
            }
        }

        task.resume()
    }
}

 // Usage example:
do {
    let networkLayer = NetworkLayer()

    networkLayer.performRequest(UserRequest.build()) { result in
        switch result {
        case .success(let user):
            print("User: \(user)")
        case .failure(let error):
            switch error {
            case .urlError(let urlError):
                print("URL Error: \(urlError)")
            case .clientError(let response, let data):
                print("Client Error: \(response.statusCode)")
                // Handle client error data if needed
            case .serverError(let response, let _):
                print("Server Error: \(response.statusCode)")
                // Handle server error data if needed
            case .decodingError(let decodingError):
                print("Decoding Error: \(decodingError)")
            case .unknownError:
                print("Unknown Error")
            }
        }
    }

} catch {
    print("Error: \(error)")
}
