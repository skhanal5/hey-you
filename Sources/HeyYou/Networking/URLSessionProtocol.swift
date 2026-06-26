import Foundation

/// Protocol to abstract URLSession for unit‑testing.
/// Allows injection of a mock session that returns predefined data.
protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}
