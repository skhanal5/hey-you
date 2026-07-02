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
    private var cancelTracking: (() -> Void)?

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
        cancelTracking = scheduler.schedule(after: delay) { [weak self] in
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
        cancelTracking?()
        cancelTracking = nil
    }

    /// User acknowledged a trigger (e.g. clicked "Back to it").
    /// Clears the cooldown so the next doomscroll starts fresh tracking.
    func acknowledgeTrigger() {
        cancelTimers()
        state = .focused
    }

    /// User acknowledged a trigger (e.g. clicked "Back to it").
    /// Clears the cooldown so the next doomscroll starts fresh tracking.
    func acknowledgeTrigger() {
        cancelTimers()
        state = .focused
    }

    func reset() {
        cancelTimers()
        state = .focused
    }
}