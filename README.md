# HeyYou

A macOS menu bar companion that calls you out when you doomscroll.

Tell it what you're working on via voice dictation. It watches your frontmost
window, and when you drift into doomscroll territory, it speaks an LLM-generated
reminder to get back on track — using your Mac's voice.

```
Idle  →  Listening  →  Active 🔵  →  Detecting 🟡  →  [Speaks]  →  Active
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

Or without bundling (Keychain prompts on every launch):

```bash
swift run
```

## Usage

1. Click the sonar icon in the menu bar
2. **Start Session** — dictate what you're working on (e.g. "finish the auth PR")
3. Work normally. When HeyYou detects doomscroll patterns (Reddit, Twitter, TikTok, etc.), it waits, then speaks a reminder
4. **Set Goal** to re-dictate mid-session, **End Session** when done

The icon shows your state:
| Icon | Meaning |
|------|---------|
| Static ring | Idle |
| Pulsing ring | Listening for goal |
| Expanding ring | Active session |
| Filled center | Detecting doomscroll |

## API Key

Your OpenRouter key is stored in the system Keychain
(`kSecClassGenericPassword`, attribute `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
It never leaves your machine and is never logged.

**Note:** Because HeyYou is ad-hoc signed (no paid Apple Developer ID), you will
see a Keychain access prompt on first launch and likely again after each update.
You may see the prompt twice — macOS SecurityAgent shows both an unlock dialog
("Enter your keychain password") and an access dialog ("App wants to use your
confidential information"). This is expected for unsigned binaries. Your key is
still stored securely in the Keychain.

## Build

```bash
make        # swift build
make test   # swift test
make bundle # .app bundle with Info.plist + ad-hoc signature
```

## Architecture

The app is layered for testability:

| Layer | Responsibility |
|-------|---------------|
| Detection | Accessibility API reads the frontmost window title |
| Classification | Regex matching against configurable doomscroll signatures |
| Session | Voice dictation for goals, manual end, trigger counting |
| Trigger | Time + frequency weighted state machine (focused → tracking → pending → triggered) |
| Intervention | AVSpeechSynthesizer with LLM-generated or fallback messages |
| UI | Menu bar icon (sonar ring), menu, preferences panel |
| LLM | OpenRouter free API via URLSession |

See `Sources/HeyYou/` — each file maps to one layer.

## Contributing

PRs welcome. See [CONTRIBUTING.md](CONTRIBUTING.md). Key conventions:

- No external dependencies
- SwiftPM only (no Xcode projects, no Makefile hacks)
- 2-space indentation
- No comments unless the code cannot be self-explanatory
- Every feature goes through a PR from a feature branch

## License

MIT
