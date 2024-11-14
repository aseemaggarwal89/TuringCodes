import Foundation

// Define a protocol for HTTPRequest
protocol HTTPRequest {
    associatedtype Response: Decodable
    
    var url: URL { get }
    var method: String { get }
    var headers: [String: String] { get }
    var body: Data? { get }
    
    static func build() -> Self
    
    func perform(completion: @escaping (Result<Response, Error>) -> Void)
}

// Implement a default extension for the HTTPRequest protocol
extension HTTPRequest {
    var headers: [String: String] {
        return [:]
    }
    
    var body: Data? {
        return nil
    }
    
    func perform(completion: @escaping (Result<Response, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NetworkLayer", code: 1001, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(Response.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
// Define a custom error enum for HTTP-related errors
enum HTTPError: Error {
    case networkError(Error)
    case invalidResponse(Error)
    case decodingError(Error)
    case other(Error)
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

// Network layer implementation
class NetworkLayer {
    func performRequest<T: HTTPRequest>(_ request: T, completion: @escaping (Result<T.Response, HTTPError>) -> Void) {
        request.perform { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(.other(error)))
            }
        }
    }
}

// Usage example
do {
    let networkLayer = NetworkLayer()
    
    // Perform UserRequest
    networkLayer.performRequest(UserRequest.build()) { result in
        switch result {
        case .success(let user):
            print("User: \(user)")
        case .failure(let error):
            switch error {
            case .networkError(let networkError):
                print("Network Error: \(networkError)")
            case .invalidResponse(let invalidResponseError):
                print("Invalid Response Error: \(invalidResponseError)")
            case .decodingError(let decodingError):
                print("Decoding Error: \(decodingError)")
            case .other(let otherError):
                print("Other Error: \(otherError)")
            }
        }
    }
    
    // Perform PostsRequest
    networkLayer.performRequest(PostsRequest.build()) { result in
        switch result {
        case .success(let posts):
            print("Posts: \(posts)")
        case .failure(let error):
            switch error {
            case .networkError(let networkError):
                print("Network Error: \(networkError)")
            case .invalidResponse(let invalidResponseError):
                print("Invalid Response Error: \(invalidResponseError)")
            case .decodingError(let decodingError):
                print("Decoding Error: \(decodingError)")
            case .other(let otherError):
                print("Other Error: \(otherError)")
            }
        }
    }
} catch {
    print("Error: \(error)")
}
