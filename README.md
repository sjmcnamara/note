# NO.TE

**Status:** v0.10.0 — Screen 9 (Tag filter)

A private, local-first note app for iPhone. Notes stay on your device. Nostr provides identity and optional encrypted backup — nothing is shared unless you ask for it.

## Stack

- iOS 17+ · iPhone only · portrait
- SwiftUI + SwiftData
- Nostr identity (secp256k1, bech32, signing) via [`rust-nostr/nostr-sdk-swift`](https://github.com/rust-nostr/nostr-sdk-swift). NIP-44 backup still pending.

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
