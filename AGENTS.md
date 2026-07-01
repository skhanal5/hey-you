# HeyYou — Agent Guide

## Build system

Swift Package Manager (SwiftPM) is the only build system.

- `swift build` — build
- `swift test` — run tests
- `swift run` — run the app
- `make` targets exist but are thin wrappers around `swift` commands

Do not bypass SwiftPM. If SwiftPM is broken, flag the issue to the user and wait. Do not switch to Makefiles, direct `swiftc` invocations, Xcode projects, or any other build mechanism without explicit permission.

## Code style

- No comments unless the code cannot be made self-explanatory
- Follow existing patterns
- Keep functions small
- Prefer clarity over brevity
- 2-space indentation

## Architecture

HeyYou is a macOS AppKit app. Its architecture is layered:

1. **Detection** — Accessibility API reads frontmost window title
2. **Classification** — Matches against configurable doomscroll signatures
3. **Session** — Voice dictation for goals, manual end
4. **Trigger** — Time + frequency weighted, focused → tracking → triggered
5. **Intervention** — AVSpeechSynthesizer with LLM-generated messages
6. **UI** — Menu bar icon (sonar ring, 4 states), contextual menu
7. **LLM** — OpenRouter free API for conversational messages

Each layer is testable independently.

## Project principles

- This is open source. Every decision must consider maintainability.
- SwiftPM only. No build system hacks.
- No external dependencies unless necessary.
- Minimal UI, maximum impact.
- The app talks to you. It does not show dialog boxes.

## Agent behavior

When implementing a feature based on a plan or discussion:

1. **Scope guard** — If you discover doubts, concerns, or work beyond what was discussed, stop and ask. Summarize what you observed. Do not edit files outside the agreed scope or implement anything without explicit permission.

2. **Tests required** — Every change that touches behavior must include a test that would catch a regression. Skip only for mechanical changes (rename, comment, config, docs).

3. **Commit hygiene** — Each commit must be a single focused unit of change, independently valid (builds + passes tests). No partial or WIP commits. A PR should contain multiple such commits rather than one large squashed commit.

## Menu bar app conventions

- Activation policy is `.accessory` (no Dock icon, no app switcher entry). Set via `LSUIElement` in Info.plist **and** `app.setActivationPolicy(.accessory)` in `main.swift` before `app.run()`.
- For preference windows: use `NSWindow` (not `NSPanel`). `NSPanel` with `.nonactivatingPanel` causes rapid deactivation/reactivation cycling on Mission Control restore in `.accessory` apps. `NSWindow` at default window level behaves correctly.
- Override `becomeKey()` to call `orderFrontRegardless()` — brings the window to front when Mission Control restores it via CGSOrderWindow, without triggering the `.accessory` deactivation cycle.
- In `show()` (initial open): call `NSApp.activate(ignoringOtherApps: true)` + `makeKeyAndOrderFront(nil)` — the app needs activation to bring the window to front for the first time.
- After Keychain read in `onAppear`: call `orderFrontRegardless()` + `makeKey()` instead of `NSApp.activate()` + `makeKeyAndOrderFront()`. `NSApp.activate()` in `.accessory` apps triggers system deactivation ~2s later, so avoid it in notification handlers or after async callbacks.
- Do NOT use `NSApp.runModal(for:)` (breaks SwiftUI TextField in `.accessory` apps) or `NSApp.setActivationPolicy(.regular)` (causes menu bar name change and close lag).

## Testing

- Use Swift Testing framework (not XCTest, not Quick/Nimble).
- Tests live in `Tests/HeyYouTests/`, named after the type or behavior they cover. Not every source file needs a dedicated test file, but every behavior change must include a regression test.
- **Every code change includes a test that would catch a regression.** If the change touches behavior, add or update a test.
- One behavior per test function. Tests are small and focused.
- `@Test("Description of behavior")` — descriptive sentences, not function names masquerading as descriptions.
- Arrange-Act-Assert pattern: blank lines separate setup from action from verification.
- `#expect(condition)` for assertions. `Issue.record("message")` for custom failure in pattern-matching branches.
- Tests must be **deterministic**: no real timers, no real network, no real keychain in unit tests.
- Dependencies are injected via initializers. No static globals or hardcoded singletons.
- `poll()` loops with RunLoop stepping are forbidden — use a virtual time scheduler instead.

## PR workflow

Every feature, fix, or change must go through a PR.

1. Create a feature branch from `main`: `git checkout -b pr/<number>-<description>`
2. Commit changes to the feature branch (see commit hygiene below)
3. Push the branch and open a PR: `gh pr create`
4. As the PR scope evolves, update the title and description via `gh pr edit`
5. Do not push directly to `main`. Do not commit and ask later. Always branch first.
6. Update AGENTS.md with any new conventions discovered during the PR.
