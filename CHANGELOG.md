# Changelog

All notable changes to NO.TE are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- Screen 2 — Timeline (in progress)

---

## [0.1.1] — 2026-04-19

### Changed
- Flattened project structure: source directories now at repo root (was `NOTE/`)
- `NOTE.xcodeproj` is now gitignored — run `xcodegen generate` after clone
- Full-screen background fix on OnboardingView
- Footer (Powered by Nostr) now always visible above home indicator

---

## [0.1.0] — 2026-04-18

### Added
- Project scaffold: xcodegen, tokens, fonts, color assets
- Adaptive color assets for all 8 design tokens (light + dark)
- Inter Tight variable font + Instrument Serif Italic
- `NoteFont`, `Space`, `Radius`, shadow helpers, `Motion` token enums
- `NostrIdentity` and `NostrBackup` protocol stubs
- `MockIdentity` and `MockBackup` for UI-only development
- Screen 1 — Onboarding: wordmark, hero, subtext, proof points, CTAs, footer
- `AdvancedSetupView` placeholder sheet
