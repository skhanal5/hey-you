import Foundation

enum EngineState: Equatable {
    case focused
    case tracking(signature: DoomscrollSignature, startTime: Date)
    case triggered(signature: DoomscrollSignature, cooldownDeadline: Date)
}

final class TriggerEngine {
    private(set) var state: EngineState = .focused {
        didSet { onStateChange?(state) }
    }

    private let sessionManager: SessionManager
    private let scheduler: Scheduler
    private var trackingCancellable: Cancellable?

    var onStateChange: ((EngineState) -> Void)?
    var onTrigger: ((DoomscrollSignature) -> Void)?

    init(sessionManager: SessionManager, scheduler: Scheduler = TimerScheduler()) {
        self.sessionManager = sessionManager
        self.scheduler = scheduler
    }

    func classificationDidChange(_ classification: Classification) {
        cancelTimers()

        switch classification {
        case .productive:
            if case .triggered(_, let deadline) = state, Date() < deadline { return }
            state = .focused
        case .doomscroll(let sig):
            if case .triggered(_, let deadline) = state, Date() < deadline {
                return
            }
            beginTracking(sig)
        }
    }

    private func beginTracking(_ sig: DoomscrollSignature) {
        state = .tracking(signature: sig, startTime: Date())
        let delay = threshold(for: sig)
        trackingCancellable = scheduler.schedule(after: delay) { [weak self] in
            self?.fireTrigger(sig)
        }
    }

    private func fireTrigger(_ sig: DoomscrollSignature) {
        guard sessionManager.shouldTrigger() else {
            state = .focused
            return
        }
        sessionManager.recordTrigger()
        let cooldown: TimeInterval = sessionManager.currentSession != nil ? 60 : 30
        state = .triggered(signature: sig, cooldownDeadline: Date().addingTimeInterval(cooldown))
        onTrigger?(sig)
    }

    private func threshold(for sig: DoomscrollSignature) -> TimeInterval {
        guard let session = sessionManager.currentSession, session.triggerCount > 0 else {
            return sig.threshold
        }
        return sig.repeatThreshold
    }

    private func cancelTimers() {
        trackingCancellable?.cancel()
        trackingCancellable = nil
    }

    func reset() {
        cancelTimers()
        state = .focused
    }
}