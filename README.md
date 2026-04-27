# NO.TE

[![CI](https://github.com/sjmcnamara/note/actions/workflows/ci.yml/badge.svg)](https://github.com/sjmcnamara/note/actions/workflows/ci.yml)
[![CodeQL](https://github.com/sjmcnamara/note/actions/workflows/codeql.yml/badge.svg)](https://github.com/sjmcnamara/note/actions/workflows/codeql.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/sjmcnamara/note/badge)](https://scorecard.dev/viewer/?uri=github.com/sjmcnamara/note)
[![codecov](https://codecov.io/gh/sjmcnamara/note/graph/badge.svg)](https://codecov.io/gh/sjmcnamara/note)

**Status:** v0.12.0 — Editor rev 2 (formatting toolbar, markdown preview, tag collapse)

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
./scripts/build.sh        # generate + build
./scripts/build.sh test   # generate + build + test
open NOTE.xcodeproj
```

> `NOTE.xcodeproj` is generated — do not commit it.

## Project structure

```
note/
├── App/          Entry point
├── Views/        Screen views
├── Design/       Token system (colors, type, spacing)
├── Domain/       Pure helpers (grouping, etc.) — testable
├── Nostr/        Identity service, Keychain, validators, models
├── Tests/        XCTest unit tests
├── Assets.xcassets/  Adaptive color assets
├── Fonts/        Inter Tight (variable) + Instrument Serif Italic
├── scripts/      build.sh (build / test / clean)
├── .github/workflows/  CI, CodeQL, Scorecard
├── project.yml   xcodegen source of truth
└── CHANGELOG.md
```

## CI

- **CI** — iOS build + test on every PR & push to master, SwiftLint `--strict`, dependency review on PRs.
- **CodeQL** — Swift static analysis on push, PR, and weekly.
- **OpenSSF Scorecard** — supply-chain hygiene check, weekly.

`./scripts/build.sh test` reproduces what CI runs locally.

## Design

Hybrid-2 — quiet minimalism. Off-white canvas, near-black ink. One humanist sans (Inter Tight) throughout. One italic serif moment per screen (Instrument Serif italic). No chrome.

Full spec in `handoff_claude_code/` (local only, not committed).
