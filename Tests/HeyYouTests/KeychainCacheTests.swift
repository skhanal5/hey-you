import Testing
@testable import HeyYou

@Test("Read returns nil from fetch on first call when empty")
func missReturnsNil() {
  var cache = KeychainCache()
  let result = cache.read { nil }
  #expect(result == nil)
}

@Test("Read returns value from fetch on first call")
func missReturnsValue() {
  var cache = KeychainCache()
  let result = cache.read { "secret" }
  #expect(result == "secret")
}

@Test("Second read returns cached value without calling fetch")
func secondReadIsCached() {
  var cache = KeychainCache()
  var fetchCount = 0

  let first = cache.read {
    fetchCount += 1
    return "secret"
  }
  #expect(first == "secret")
  #expect(fetchCount == 1)

  let second = cache.read {
    fetchCount += 1
    return "tampered"
  }
  #expect(second == "secret")
  #expect(fetchCount == 1)
}

@Test("Invalidate clears cache so next read calls fetch again")
func invalidateForcesRefetch() {
  var cache = KeychainCache()

  let first = cache.read { "original" }
  #expect(first == "original")

  cache.invalidate()

  let second = cache.read { "fresh" }
  #expect(second == "fresh")
}

@Test("Read caches nil from fetch and returns nil on subsequent reads")
func cachesNilFromFetch() {
  var cache = KeychainCache()

  let first = cache.read { nil }
  #expect(first == nil)

  var fetchCalled = false
  let second = cache.read {
    fetchCalled = true
    return "should-not-reach"
  }
  #expect(second == nil)
  #expect(!fetchCalled)
}

@Test("Read returns new value after invalidation even if fetch returns nil")
func invalidateThenFetchNil() {
  var cache = KeychainCache()

  let first = cache.read { "value" }
  #expect(first == "value")

  cache.invalidate()

  let second = cache.read { nil }
  #expect(second == nil)
}
