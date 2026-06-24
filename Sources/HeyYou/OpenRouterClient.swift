import Foundation

final class OpenRouterClient {
    private let session = URLSession.shared
    private let baseURL = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    struct Message: Codable {
        let role: String
        let content: String
    }

    struct Request: Encodable {
        let model = "openrouter/free"
        let messages: [Message]
    }

    struct Response: Decodable {
        let choices: [Choice]
    }

    struct Choice: Decodable {
        let message: Message
    }

    func generate(prompt: String) async throws -> String {
        guard let key = KeychainService.read() else {
            throw Error.noKey
        }

        var urlRequest = URLRequest(url: baseURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        let body = Request(messages: [Message(role: "user", content: prompt)])
        urlRequest.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await session.data(for: urlRequest)
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.choices.first?.message.content ?? ""
    }

    enum Error: Swift.Error {
        case noKey
    }
}
