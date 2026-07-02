import Foundation
@testable import HeyYou

final class TestScheduler: Scheduler {
  private struct ScheduledBlock {
    let id: UUID
    let fireDate: Date
    let block: () -> Void
  }

  private var now = Date()
  private var blocks: [ScheduledBlock] = []

  func schedule(after delay: TimeInterval, _ block: @escaping () -> Void) -> () -> Void {
    let fireDate = now.addingTimeInterval(delay)
    let id = UUID()
    blocks.append(ScheduledBlock(id: id, fireDate: fireDate, block: block))
    blocks.sort { $0.fireDate < $1.fireDate }
    return { [weak self] in
      self?.blocks.removeAll { $0.id == id }
    }
  }

  func advance(by interval: TimeInterval) {
    let target = now.addingTimeInterval(interval)
    while true {
      let dueThisStep = blocks.filter { $0.fireDate <= target && $0.fireDate > now }
      let earliestDue = dueThisStep.min { $0.fireDate < $1.fireDate }
      guard let next = earliestDue else { break }

      now = next.fireDate
      blocks.removeAll { $0.id == next.id }
      next.block()
    }
    now = target
    let due = blocks.filter { $0.fireDate <= target }
    blocks.removeAll { $0.fireDate <= target }
    for block in due {
      block.block()
    }
  }

  func advanceUntil(deadline: Date) {
    advance(by: deadline.timeIntervalSince(now))
  }
}
