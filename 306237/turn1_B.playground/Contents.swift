
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

// Network layer implementation
class NetworkLayer {
    func performRequest<T: HTTPRequest>(_ request: T, completion: @escaping (Result<T.Response, Error>) -> Void) {
        // Create URLSessionDataTask to perform the HTTP request
        let task = URLSession.shared.dataTask(with: request.url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NetworkLayer", code: 1001, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Transform the JSON data to the expected response struct using the transformResponse function
            if let response = request.transformResponse(data) {
                completion(.success(response))
            } else {
                completion(.failure(NSError(domain: "NetworkLayer", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to transform response"])))
            }
        }
        
        // Start the URLSessionDataTask
        task.resume()
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
            print("Error: \(error)")
        }
    }
    
    // Perform PostsRequest
    networkLayer.performRequest(PostsRequest.build()) { result in
        switch result {
        case .success(let posts):
            print("Posts: \(posts)")
        case .failure(let error):
            print("Error: \(error)")
        }
    }
}
