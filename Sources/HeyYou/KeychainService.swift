import Foundation
import Security

final class KeychainService {
  static let service = "com.skhanal5.hey-you"
  static let account = "openrouter-key"

  private static var cachedKey: String?
  private static var keyChecked = false

  @discardableResult
  static func save(key: String) -> Bool {
    NSLog("[KEYCHAIN] \(#function) called, account=\(account)")
    keyChecked = false
    cachedKey = nil
    let data = Data(key.utf8)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    SecItemDelete(query as CFDictionary)

    var attributes = query
    attributes[kSecValueData as String] = data
    attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
  }

  static func read() -> String? {
    NSLog("[KEYCHAIN] \(#function) called, account=\(account)")
    if keyChecked {
      NSLog("[KEYCHAIN] \(#function) returning cached value")
      return cachedKey
    }
    keyChecked = true
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var result: AnyObject?
    guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
          let data = result as? Data else {
      NSLog("[KEYCHAIN] \(#function) no item found")
      return nil
    }
    cachedKey = String(data: data, encoding: .utf8)
    NSLog("[KEYCHAIN] \(#function) key loaded")
    return cachedKey
  }

  static func delete() {
    NSLog("[KEYCHAIN] \(#function) called, account=\(account)")
    keyChecked = false
    cachedKey = nil
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    SecItemDelete(query as CFDictionary)
  }
}
