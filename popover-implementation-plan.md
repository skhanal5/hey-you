# Popover UI Implementation Plan

Split into three PRs. Each PR is a single logical change with its own tests.
Branch from `main` for each PR. Do not stack branches.

---

## PR 1: Voice Dictation Streaming + Session Stats

**Branch**: `pr/1-voice-streaming-session-stats`

### Motivation
DictationService currently returns a single string after recording stops. For
the live transcription UI we need a streaming callback. SessionManager needs
aggregate stats for the active state stat chips.

### Changes

#### Sources/HeyYou/DictationService.swift — Streaming + errors

- New `startRecording(withPartialResult: @escaping (String) -> Void)` overload
  that yields partial transcriptions in real time
- `requiresOnDeviceRecognition = true` on the `SFSpeechAudioBufferRecognitionRequest`
- Auto-stop after 1.5s of silence (compare `Date()` against last partial result
  timestamp; call `engine.stop()` + `request.endAudio()` when threshold exceeded)
- New error enum cases:
  - `microphonePermissionDenied`
  - `recognitionUnavailable`
  - `recognitionFailed(Error)`
- No API breakage: keep the existing `stopRecording()` → `String` for Set Goal voice flow

#### Sources/HeyYou/SessionManager.swift — Stats extension

New properties:

```swift
var sessionsToday: Int { get }
var totalFocusTimeToday: TimeInterval { get }
var snoozeUntil: Date? { get set }
```

- `endSession()` increments `sessionsToday` and adds elapsed time to
  `totalFocusTimeToday`. Reset both to `0` on calendar day change (check
  `Calendar.current.isDateInToday` before each increment).
- `snoozeUntil` is set by the detection "5 more min" action. No time-of-day
  awareness — just a `Date` comparison. `TriggerEngine.classificationDidChange`
  checks `snoozeUntil > Date()` before firing; resets to `nil` on trigger or
  session end.

#### Info.plist

Add key `NSSpeechRecognitionUsageDescription`:

```
Hey You uses speech recognition to set your focus goal. Audio is processed on-device and never sent anywhere.
```

### Tests

| Test file | What |
|---|---|
| `Tests/HeyYouTests/SessionManagerTests.swift` | Extend: sessionsToday increments on endSession, totalFocusTimeToday accumulates, snoozeUntil set/get, day-boundary reset |
| `Tests/HeyYouTests/DictationServiceTests.swift` | Streaming callback fires partial results, on-device flag set, silence auto-stop, error states for denied/unavailable/failure |

### Verification

```bash
swift test 2>&1 | tail -5
# All existing tests pass + new tests pass
```

---

## PR 2: SessionState Enum + Popover SwiftUI Views

**Branch**: `pr/2-popover-views`

### Motivation
All the UI primitives — card shell, sonar ping indicator, three state layouts.
Pure SwiftUI, no AppKit wiring. Fully testable in isolation.

### Changes

#### Sources/HeyYou/SessionState.swift (new)

```swift
enum SessionState: Equatable {
  case idle
  case active(goal: String, startTime: Date, distractions: Int)
  case detection(goal: String, site: String, elapsedMinutes: Int)
}
```

#### Sources/HeyYou/CardShell.swift (new)

ViewModifier applied to all three state views:

```swift
func modifier(for width: CGFloat = 300) -> some ViewModifier
```

- `background(.ultraThinMaterial)`
- `background(Color(red: 0.11, green: 0.118, blue: 0.141).opacity(0.88))`
- `.cornerRadius(20)`
- `.overlay(RoundedRectangle(cornerRadius: 20).stroke(LinearGradient(...), lineWidth: 1))`
- Fixed `frame(width: 300)`, no explicit height
- 20pt padding

#### Sources/HeyYou/SonarPingView.swift (new)

Three concentric ring circles:

| Ring | Diameter | Opacity |
|---|---|---|
| Inner | 10pt | 0.9 |
| Middle | 18pt | 0.35 |
| Outer | 26pt | 0.12 |

State colors: idle = white(0.25), active = #4ade80, detection = #fb7185

Active state: continuous scale(1.0→1.6) + opacity(0.35→0) loop on outer ring,
`withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: false))`.

#### Sources/HeyYou/IdleStateView.swift (new)

- SonarPingView (idle colors) + "IDLE · NOT WATCHING" label
- Hero text: "What are you here to do?" (19pt, weight 600, white)
- Mic button (ghost circle, centered) — calls `onStartListening` closure
- Live transcription text below mic (if listening)
- "tap to confirm" state (if has partial transcription)
- "type instead" link (12pt, white @ 25% opacity) — reveals TextField
- Permission denied error state with Settings link button
- Recognition error "Didn't catch that — try again" inline reset
- "Start session" / "Not yet" buttons (after goal confirmed or typed)

Closures: `onStartListening`, `onStopListening`, `onConfirmGoal(String)`,
`onDismiss`, `onTypeGoal(String)`, `onOpenSettings`

#### Sources/HeyYou/ActiveStateView.swift (new)

- SonarPingView (active green) + "WATCHING · SESSION ACTIVE" label
- Goal chip: full-width, rgba(255,255,255,0.05) bg, 4ade80 dot, goal text
- Timer: 36pt weight 300, with `Timer.publish(every: 1, on: .main, in: .common)`,
  colon separator white @ 40% opacity, "elapsed" label
- Three stat chips in HStack (equal width):
  - Distractions (green tint if 0)
  - Sessions today
  - Total focus time today
- "End session" ghost button (full width)

Closures: `onEndSession`

#### Sources/HeyYou/DetectionStateView.swift (new)

- SonarPingView (detection red-pink) + "CAUGHT SOMETHING" + close button
- Hero: "You've been gone for N minutes."
- Subtext: "site.com · still open."
- Goal chip: red-tinted bg/border, #fb7185 dot
- "Back to it" button (#fb7185 bg, white, pill)
- "5 more min" ghost button (snooze)

Closures: `onDismiss`, `onBackToWork`, `onSnooze`

#### Sources/HeyYou/PopoverContentView.swift (new)

Root view containing all three sub-views:

```swift
struct PopoverContentView: View {
  @Binding var state: SessionState
  // action closures for each state
  var body: some View {
    Group {
      switch state {
      case .idle: IdleStateView(...)
      case .active(...): ActiveStateView(...)
      case .detection(...): DetectionStateView(...)
      }
    }
    .modifier(CardShell())
    .transition(.opacity.combined(with: .scale(scale: 0.97)))
    .animation(.easeInOut(duration: 0.25), value: state)
  }
}
```

### Tests

| Test file | What |
|---|---|
| `Tests/HeyYouTests/SessionStateTests.swift` | Init, equality, associated value access |
| `Tests/HeyYouTests/PopoverContentViewTests.swift` | Each state renders correct view type, state transitions produce correct new view |

View rendering tests are limited by SwiftUI testability — focus on state
mapping correctness rather than pixel-level assertions.

### Verification

```bash
swift test 2>&1 | tail -5
```

---

## PR 3: NSPopover Wiring + AppDelegate Integration

**Branch**: `pr/3-popover-wiring`

### Motivation
Replace NSMenu with NSPopover on the status item button. Wire detection
state with real site/elapsed data from the trigger engine. This is the
integration layer.

### Changes

#### Sources/HeyYou/MenuBarController.swift — Popover replacement

- Remove `rebuildMenu()` and `menu` property
- Add `NSPopover` instance with `NSHostingController<PopoverContentView>`
- Map `MenuBarState` → `SessionState` and pass to the popover content view
- Left-click on status item button: toggle popover (show if hidden, close if
  shown). Use `statusItem.button?.action` and `button?.sendAction(on: .leftMouseUp)`
- Right-click on status item button: show minimal `NSMenu` with Preferences
  and Quit only
- `NSApplication.didBecomeActiveNotification` observer: call
  `popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)`
  when the popover is currently shown
- Keep `MenuBarIcon` and `MenuBarState` for the status item icon drawing
- Actions from the popover (start session, end session, snooze, etc.) call
  the same `@objc` methods already in `MenuBarController`

#### Sources/HeyYou/MenuBarState.swift — Extend with SessionState mapping

Add a computed property or method to the existing enum:

```swift
var asSessionState: SessionState? {
  switch self {
  case .idle, .listening: return .idle
  case .active(let g, let t): return .active(goal: g, startTime: ..., distractions: t)
  case .detecting(let g, let t): return .detection(goal: g, site: ..., elapsedMinutes: ...)
  case .speaking(let g, let t): return .detection(goal: g, site: ..., elapsedMinutes: ...)
  }
}
```

#### Sources/HeyYou/AppDelegate.swift — Detection state wiring

- Track `lastTriggerTime` and `lastSignatureName` for popover detection state
- In `onStateChange(.triggered)`: capture the signature name and elapsed
  tracking time, update the popover's `SessionState` to `.detection`

#### Sources/HeyYou/SessionManager.swift — Snooze check

- `shouldTrigger() -> Bool`: returns `snoozeUntil == nil || Date() >= snoozeUntil`
- Called by `TriggerEngine.fireTrigger()` before recording the trigger
- `reset()` also clears `snoozeUntil`

### Tests

| Test file | What |
|---|---|
| `Tests/HeyYouTests/MenuBarControllerTests.swift` | Popover shows/hides on left-click, right-click shows menu, state mapping |
| `Tests/HeyYouTests/SessionManagerTests.swift` | Extend: snoozeUntil blocks trigger, clears on trigger, clears on reset |

MenuBarController tests require careful setup since they create real
`NSStatusItem` objects. Focus on the state mapping logic and popover
lifecycle methods rather than pixel-level assertions.

### Verification

```bash
swift build && swift test 2>&1 | tail -5
```

Manual: launch the app, verify left-click shows popover, right-click shows
menu, all three popover states render correctly, mic flow works, detection
popover appears on trigger.

---

## Dependency Graph

```
PR 1 (dictation + stats) ──┐
                            ├──→ PR 3 (wiring)
PR 2 (views + state) ──────┘
```

PR 1 and PR 2 can be built in parallel. PR 3 depends on both.
Each PR absorbs its own tests — no deferred testing.
