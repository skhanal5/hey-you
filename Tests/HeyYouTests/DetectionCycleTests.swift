import Foundation
import Testing
@testable import HeyYou

@Test("ensureFirstDetectedAt sets timestamp on first call")
func setsTimestampOnFirstCall() {
  var cycle = DetectionCycle()
  #expect(cycle.firstDetectedAt == nil)

  cycle.ensureFirstDetectedAt()
  #expect(cycle.firstDetectedAt != nil)
}

@Test("ensureFirstDetectedAt does not overwrite existing timestamp")
func preservesExistingTimestamp() {
  var cycle = DetectionCycle()
  let fixed = Date(timeIntervalSinceReferenceDate: 0)
  cycle.firstDetectedAt = fixed

  cycle.ensureFirstDetectedAt()
  #expect(cycle.firstDetectedAt == fixed)
}

@Test("incrementFireCount increases by one each call")
func incrementFireCount() {
  var cycle = DetectionCycle()
  #expect(cycle.fireCount == 0)

  cycle.incrementFireCount()
  #expect(cycle.fireCount == 1)

  cycle.incrementFireCount()
  #expect(cycle.fireCount == 2)
}

@Test("reset clears both firstDetectedAt and fireCount")
func resetClearsState() {
  var cycle = DetectionCycle()
  cycle.firstDetectedAt = Date()
  cycle.fireCount = 3

  cycle.reset()
  #expect(cycle.firstDetectedAt == nil)
  #expect(cycle.fireCount == 0)
}
