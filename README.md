# NO.TE

**Status:** v0.2.0 — Timeline

A private, local-first note app for iPhone. Notes stay on your device. Nostr provides identity and optional encrypted backup — nothing is shared unless you ask for it.

## Stack

- iOS 17+ · iPhone only · portrait
- SwiftUI + SwiftData
- Nostr identity and E2EE backup (NIP-44 v2) via `nostr-sdk-ios`

## Getting started

**Prerequisites**

```bash
brew install xcodegen
```

**Setup**

```bash
git clone git@github.com:sjmcnamara/note.git
cd note
xcodegen generate
open NOTE.xcodeproj
```

> `NOTE.xcodeproj` is generated — do not commit it.

## Project structure

```
note/
├── App/          Entry point
├── Views/        Screen views
├── Design/       Token system (colors, type, spacing)
├── Nostr/        Protocol stubs and mocks
├── Assets.xcassets/  Adaptive color assets
├── Fonts/        Inter Tight (variable) + Instrument Serif Italic
├── project.yml   xcodegen source of truth
└── CHANGELOG.md
```

## Design

Hybrid-2 — quiet minimalism. Off-white canvas, near-black ink. One humanist sans (Inter Tight) throughout. One italic serif moment per screen (Instrument Serif italic). No chrome.

Full spec in `handoff_claude_code/` (local only, not committed).
