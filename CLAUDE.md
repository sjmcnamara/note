# CLAUDE.md — NO.TE project guidance

## Project setup

`NOTE.xcodeproj` is generated — never commit it. After cloning or adding new source files:

```bash
xcodegen generate
open NOTE.xcodeproj
```

Source directories picked up automatically by xcodegen: `App/`, `Views/`, `Design/`, `Nostr/`, `Fonts/`, `Assets.xcassets/`.

## Spec source

All design specs live in `handoff_claude_code/` (local only, not committed):

- `handoff_claude_code/spec/NN-screen.md` — per-screen layout, interactions, copy keys
- `handoff_claude_code/design/Notes app wireframes.html` — Hybrid-2 tab is ground truth; open in a browser alongside coding
- `handoff_claude_code/copy.md` — every user-facing string, verbatim
- `handoff_claude_code/tokens/Tokens.swift` + `tokens.json` — design token reference

**If a spec contradicts the wireframe, the wireframe wins.**

## Design rules

- **Tokens only** — no ad-hoc colors, sizes, or spacings anywhere in SwiftUI views. Everything comes from `Design/Tokens.swift` (`Color.*`, `NoteFont.*`, `Space.*`, `Radius.*`, shadow view modifiers).
- One Instrument Serif italic moment per screen (`NoteFont.italic(_ size:)`), never more.
- No emoji in UI.

## Screen status

| # | Screen | Status |
|---|--------|--------|
| 0 | Bootstrap — tokens, fonts, protocols, mocks | Done |
| 1 | Onboarding | Done |
| 2 | Timeline | Done |
| 3 | Search & Ask | Stub (`Views/SearchView.swift`) |
| 4 | Editor | Stub (`Views/EditorView.swift`) |
| 5 | Settings | Stub (`Views/SettingsView.swift`) |
| 6 | Advanced setup | Stub (`Views/AdvancedSetupView.swift`) |
| 7 | Key import | Not started |
| 8 | Empty state | Not started |
| 9 | Tag filter | Not started |
| 10 | Share & export | Not started |
| 11 | Night mode audit | Not started |
| 12 | Real Nostr | Not started |

## Nostr posture

All screens through 11 use `MockIdentity` and `MockBackup` — no real relay connections. Real Nostr (screen 12) is the last thing to land, behind a feature flag.

## Versioning

`project.yml` does not yet have `MARKETING_VERSION` or `CURRENT_PROJECT_VERSION` keys — add them under `settings.base` when doing the first version bump. Then add a CHANGELOG entry and update the README status line.

## Branch strategy

**All changes must go via a branch and PR — no direct commits to master, no exceptions.** This includes housekeeping, roadmap updates, changelog entries, and version bumps.

Branch naming: `feature/vX.Y-description`, `bugfix/vX.Y.Z`, `chore/description`. PR per branch → review → merge to master. ROADMAP.md tracks branch history; update it when a branch merges.
