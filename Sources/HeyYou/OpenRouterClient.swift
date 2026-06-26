import Foundation
import Foundation

final class OpenRouterClient {
    let model: String
    private let session: URLSessionProtocol
    private let baseURL = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    private let keychain: KeychainServiceProtocol

    struct Message: Codable {
        let role: String
        let content: String
    }

    struct Request: Encodable {
        let model: String
        let messages: [Message]
    }

    init(model: String = "openrouter/free", keychain: KeychainServiceProtocol, session: URLSessionProtocol = URLSession.shared) {
        self.model = model
        self.keychain = keychain
        self.session = session
    }

    struct Response: Decodable {
        let choices: [Choice]
    }

    struct Choice: Decodable {
        let message: Message
    }

    func generate(prompt: String) async throws -> String {
        guard let key = keychain.read() else {
            throw Error.noKey
        }
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let body = Request(model: model, messages: [Message(role: "user", content: prompt)])
        urlRequest.httpBody = try JSONEncoder().encode(body)
        do {
            let (data, _) = try await session.data(for: urlRequest)
            let response = try JSONDecoder().decode(Response.self, from: data)
            return response.choices.first?.message.content ?? ""
        } catch let err as DecodingError {
            throw Error.decoding(err)
        } catch {
            throw Error.network(error)
        }
    }

    enum Error: Swift.Error {
        case noKey
        case network(Swift.Error)
        case decoding(Swift.Error)
    }
}
