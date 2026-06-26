import Testing
import Foundation
@testable import HeyYou

@Test("All signatures have valid regex patterns")
func allSignaturesValid() {
  for sig in defaultDoomscrollSignatures {
    for pattern in sig.patterns {
      #expect((try? NSRegularExpression(pattern: pattern)) != nil, "Invalid regex: \(pattern)")
    }
  }
}

@Test("All signatures have positive thresholds")
func allThresholdsPositive() {
  for sig in defaultDoomscrollSignatures {
    #expect(sig.threshold > 0, "\(sig.name) has zero threshold")
    #expect(sig.repeatThreshold > 0, "\(sig.name) has zero repeatThreshold")
  }
}

@Test("All signatures have non-empty patterns")
func allSignaturesHavePatterns() {
  for sig in defaultDoomscrollSignatures {
    #expect(!sig.patterns.isEmpty, "\(sig.name) has no patterns")
  }
}

@Test("All signatures have non-empty names")
func allSignaturesHaveNames() {
  for sig in defaultDoomscrollSignatures {
    #expect(!sig.name.isEmpty)
  }
}

@Test("Signature count matches expected")
func signatureCount() {
  #expect(defaultDoomscrollSignatures.count >= 10)
}
