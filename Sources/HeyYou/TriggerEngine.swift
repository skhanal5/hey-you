import Foundation

enum EngineState: Equatable {
    case focused
    case tracking(signature: DoomscrollSignature, startTime: Date)
    case pending(signature: DoomscrollSignature, cancelDeadline: Date)
    case triggered(signature: DoomscrollSignature, cooldownDeadline: Date)
}

final class TriggerEngine {
    private(set) var state: EngineState = .focused {
        didSet { onStateChange?(state) }
    }

    private let sessionManager: SessionManager
    private let pendingDelay: TimeInterval
    private var trackingTimer: Timer?
    private var pendingTimer: Timer?

    var onStateChange: ((EngineState) -> Void)?
    var onTrigger: ((DoomscrollSignature) -> Void)?

    init(sessionManager: SessionManager, pendingDelay: TimeInterval = 2.5) {
        self.sessionManager = sessionManager
        self.pendingDelay = pendingDelay
    }

    func classificationDidChange(_ classification: Classification) {
        cancelTimers()

        switch classification {
        case .productive:
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
        trackingTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.beginPending(sig)
        }
    }

    private func beginPending(_ sig: DoomscrollSignature) {
        state = .pending(signature: sig, cancelDeadline: Date().addingTimeInterval(pendingDelay))
        pendingTimer = Timer.scheduledTimer(withTimeInterval: pendingDelay, repeats: false) { [weak self] _ in
            self?.fireTrigger(sig)
        }
    }

    private func fireTrigger(_ sig: DoomscrollSignature) {
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
        trackingTimer?.invalidate()
        trackingTimer = nil
        pendingTimer?.invalidate()
        pendingTimer = nil
    }

    func reset() {
        cancelTimers()
        state = .focused
    }
}
