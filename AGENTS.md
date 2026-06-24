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
4. **Trigger** — Time + frequency weighted, pulse → cancel → speak
5. **Intervention** — AVSpeechSynthesizer with LLM-generated messages
6. **UI** — Floating colored dot (green/yellow/red), draggable
7. **LLM** — OpenRouter free API for conversational messages

Each layer is testable independently.

## Project principles

- This is open source. Every decision must consider maintainability.
- SwiftPM only. No build system hacks.
- No external dependencies unless necessary.
- Minimal UI, maximum impact.
- The app talks to you. It does not show dialog boxes.
