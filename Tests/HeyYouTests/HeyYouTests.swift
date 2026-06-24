import Testing
@testable import HeyYou

@Test("App delegate can be created")
func appDelegateCreation() {
    let delegate = AppDelegate()
    #expect(delegate.isKind(of: AppDelegate.self))
}
