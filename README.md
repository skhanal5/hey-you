# HeyYou

A macOS menu bar companion that calls you out when you doomscroll.

Tell it what you're working on via voice dictation. It watches your frontmost
window, and when you drift into doomscroll territory, it speaks an LLM-generated
reminder to get back on track.

```
Idle → Listening → Active → Detecting → [Speaks] → Active
```

Built with Swift, AppKit, the Accessibility API, and a conversational LLM over
OpenRouter.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15+ or the Swift 5.9+ toolchain
- An [OpenRouter](https://openrouter.ai) API key (free tier works)

## Install

### From a release

1. Download `HeyYou.zip` from the [latest release](https://github.com/skhanal5/hey-you/releases)
2. Unzip and drag `HeyYou.app` to Applications
3. Right-click → Open (first launch only — ad-hoc signed, not notarized)
4. Enter your OpenRouter API key in Preferences (⌘,)

### From source

```bash
git clone https://github.com/skhanal5/hey-you
cd hey-you
make bundle
open .build/HeyYou.app
```

Or to run without bundling (Keychain prompts on every launch):

```bash
swift run
```

## Usage

1. Click the sonar icon in the menu bar
2. Dictate what you're working on (e.g. "finish the auth PR")
3. Work normally. When HeyYou detects doomscroll patterns, it speaks a reminder
4. **Set Goal** to re-dictate mid-session, **End Session** when done

The icon shows your state: static ring (idle), pulsing ring (listening), expanding
ring (active), filled center (detecting doomscroll).

## API Key

Your OpenRouter key is stored in the system Keychain and never leaves your machine.
Because HeyYou is ad-hoc signed (no paid Apple Developer ID), you will see a Keychain
access prompt on first launch and likely again after each update.

## Build

```bash
make        # swift build
make test   # swift test
make bundle # .app bundle with Info.plist + ad-hoc signature
```

## License

MIT
