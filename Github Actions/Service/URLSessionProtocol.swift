import Foundation

// Protocol for URLSession
protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// Conform URLSession to URLSessionProtocol
extension URLSession: URLSessionProtocol {}
