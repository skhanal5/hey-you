import Foundation
import Security

protocol KeychainServiceProtocol: AnyObject {
  func read() -> String?
  @discardableResult func save(key: String) -> Bool
  func delete()
}

struct KeychainCache {
  private var cachedKey: String?
  private var keyChecked = false

  mutating func read(fetch: () -> String?) -> String? {
    if keyChecked {
      return cachedKey
    }
    keyChecked = true
    let value = fetch()
    cachedKey = value
    return value
  }

  mutating func invalidate() {
    cachedKey = nil
    keyChecked = false
  }
}

final class KeychainService: KeychainServiceProtocol {
  static let service = "com.skhanal5.hey-you"
  static let account = "openrouter-key"

  private var cache = KeychainCache()

  @discardableResult
  func save(key: String) -> Bool {
    cache.invalidate()
    let data = Data(key.utf8)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Self.service,
      kSecAttrAccount as String: Self.account,
    ]
    SecItemDelete(query as CFDictionary)

    var attributes = query
    attributes[kSecValueData as String] = data
    attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
  }

  func read() -> String? {
    cache.read { () -> String? in
      let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: Self.service,
        kSecAttrAccount as String: Self.account,
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne,
      ]
      var result: AnyObject?
      guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
            let data = result as? Data else {
        return nil
      }
      return String(data: data, encoding: .utf8)
    }
  }

  func delete() {
    cache.invalidate()
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Self.service,
      kSecAttrAccount as String: Self.account,
    ]
    SecItemDelete(query as CFDictionary)
  }
}
