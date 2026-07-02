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
    let result = try await client.generate(systemPrompt: "You are helpful.", userPrompt: "hi")
    // Assert
    #expect(result == "Hello world")
  }

  @Test("generate rejects guardrail response")
  func generateRejectsGuardrail() async throws {
    // Arrange
    let json = """
    {"choices":[{"message":{"role":"assistant","content":"User safety: safe"}}]}
    """
    let data = Data(json.utf8)
    let session = MockURLSession(data: data)
    let keychain = FakeKeychain(key: "test-key")
    let client = OpenRouterClient(keychain: keychain, session: session)
    // Act / Assert
    do {
      _ = try await client.generate(systemPrompt: "x", userPrompt: "x")
      Issue.record("Expected invalidResponse error")
    } catch OpenRouterClient.Error.invalidResponse {
      // Pass
    }
  }

  @Test("isValidMessage rejects guardrail prefix")
  func guardrailPatterns() {
    #expect(!OpenRouterClient.isValidMessage("User safety: safe"))
    #expect(!OpenRouterClient.isValidMessage("safety: unsafe"))
    #expect(!OpenRouterClient.isValidMessage("harm category: none"))
    #expect(!OpenRouterClient.isValidMessage("content policy: ok"))
  }

  @Test("isValidMessage rejects too-short responses")
  func shortResponses() {
    #expect(!OpenRouterClient.isValidMessage(""))
    #expect(!OpenRouterClient.isValidMessage("Hi"))
    #expect(!OpenRouterClient.isValidMessage("     "))
  }

  @Test("isValidMessage accepts valid messages")
  func validMessages() {
    #expect(OpenRouterClient.isValidMessage("Remember your essay is due tomorrow."))
    #expect(OpenRouterClient.isValidMessage("Hey — you're on Reddit again. Back to work?"))
    #expect(OpenRouterClient.isValidMessage("Your notes are waiting for you to finish them."))
  }
}
