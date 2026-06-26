import Foundation

protocol Cancellable: AnyObject {
  func cancel()
}

protocol Scheduler: AnyObject {
  func schedule(after delay: TimeInterval, _ block: @escaping () -> Void) -> Cancellable
}

final class TimerCancellable: Cancellable {
  private weak var timer: Timer?

  init(timer: Timer) {
    self.timer = timer
  }

  func cancel() {
    timer?.invalidate()
    timer = nil
  }
}

final class TimerScheduler: Scheduler {
  func schedule(after delay: TimeInterval, _ block: @escaping () -> Void) -> Cancellable {
    let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
      block()
    }
    return TimerCancellable(timer: timer)
  }
}
