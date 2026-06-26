@testable import HeyYou
import Foundation
import Testing

final class OpenRouterClientTests {
    struct MockURLSession: URLSessionProtocol {
        var data: Data
        var response: URLResponse = URLResponse()
        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            return (data, response)
        }
    }

    final class FakeKeychain: KeychainServiceProtocol {
        var key: String?
        init(key: String?) { self.key = key }
        func read() -> String? { key }
        @discardableResult func save(key: String) -> Bool { true }
        func delete() {}
    }

    @Test("generate returns content from response")
    func generateSuccess() async throws {
        // Arrange
        let json = """
        {"choices":[{"message":{"role":"assistant","content":"Hello world"}}]}
        """
        let data = Data(json.utf8)
        let session = MockURLSession(data: data)
        let keychain = FakeKeychain(key: "test-key")
        let client = OpenRouterClient(keychain: keychain, session: session)
        // Act
        let result = try await client.generate(prompt: "hi")
        // Assert
        #expect(result == "Hello world")
    }
}
