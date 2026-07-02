import Foundation

protocol Scheduler: AnyObject {
  func schedule(after delay: TimeInterval, _ block: @escaping () -> Void) -> () -> Void
}

final class TimerScheduler: Scheduler {
  func schedule(after delay: TimeInterval, _ block: @escaping () -> Void) -> () -> Void {
    let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
      block()
    }
    return { timer.invalidate() }
  }
}
