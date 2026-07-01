# Future improvements

## 1. Session start without API key

Currently `startSession()` checks `keychain.read() != nil` and routes to Preferences if
unset. Instead, the idle popover should show a message prompting the user to configure an
API key, with a link/button to open Preferences. No session start is possible until the
key is set.

## 2. Keychain prompt appears twice

On first launch (no key in Keychain), the system keychain prompt appears twice. Likely
causes: redundant `keychain.read()` calls during initialization, or a notification
handler that re-reads before the first prompt completes. Needs investigation and a guard.

## 3. Unacknowledged detection — icon reverts to idle/active

When a detection popover appears (trigger fires), the menu bar icon should stay in the
detecting state (filled center) until the user explicitly acknowledges it by tapping
"Back to it" or "5 more min" (or the X button). Currently the icon switches back to the
active/idle state even when the popover is still open and the user hasn't dismissed it.

## 4. Menu bar icon ring too thick — pulse effect hard to see

The menu bar icon's base ring (innerStroke: 2.5pt) is thick enough that the subtle
pulse animation (±8% size change) in the listening state is nearly invisible. The idle
and listening states are visually indistinguishable. Consider reducing the stroke width
or increasing the pulse amplitude.

## 5. Multiple detections / wrong site capture

After a detection fires (e.g., on X/Twitter), switching to a non-doomscroll site (e.g.,
Claude.ai) sometimes triggers another detection. Possible causes: leftover popover state
from the first detection, cooldown expiry + quick re-classification, or the `onAppChange`
callback firing with stale data. Needs investigation with console logging.
