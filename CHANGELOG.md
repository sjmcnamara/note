# Changelog

All notable changes to NO.TE are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

---

## [0.5.1] — 2026-04-24

### Added
- `AboutView` — app version + build (read from `CFBundleShortVersionString` / `CFBundleVersion`), NO.TE wordmark, "Powered by Nostr" credit
- `AdvancedSettingsView` — houses Identity card, Private Backup card, and Change keys / Restore rows (both linking to `AdvancedSetupView` stub)
- `MARKETING_VERSION` (0.5.1) and `CURRENT_PROJECT_VERSION` (1) added to `project.yml`

### Changed
- Settings split into Basic / Advanced / About. Basic screen now only contains Appearance, Text size, and two nav rows (About, Advanced)
- Text size slider labels: every step gets a unique label (X-Small, Smaller, Small, Default, Large, Larger, X-Large)
- Every `NoteFont` token now uses `relativeTo:` — the text size slider applies `dynamicTypeSize(...)` at the root so all app text scales together
- Footer wordmark moved from Settings to About

### Removed
- `Tag suggestions` toggle (no design, will be implicit when tag autocomplete ships)
- `Morning prompt` toggle (no design, no clear use case)

---

## [0.5.0] — 2026-04-24

### Added
- Screen 5 — Settings: full implementation replacing stub
- `IdentityCard` — conic-gradient avatar derived from npub, monospace-ellipsized npub with clipboard copy + haptic, nsec row with FaceID-gated reveal (auto-hides after 30 s), footer with "Back up now" link
- `AppearancePicker` — three mini-preview tiles (Light / Night / System); active tile has 2pt ink border; selection stored in `@AppStorage("appearance")`
- `SettingRows` — Text size (−/+ steps: Small / Default / Large, stored in `@AppStorage("textSizeStep")`), Tag suggestions toggle, Morning prompt toggle
- `PrivateBackupCard` — shield icon, E2EE badge, enable toggle, body copy with *nsec* in Instrument Serif italic, relay row with halo dot + status, Add relay and Restore outline buttons
- `FooterWordmark` — centered 10.5pt inkMute text at bottom of scroll
- `ContentView` now reads `@AppStorage("appearance")` and applies `.preferredColorScheme()` globally; switching themes takes effect instantly
- `NSFaceIDUsageDescription` added to `project.yml` / `Info.plist`

### Changed
- `NostrIdentity` protocol — added `var nsec: String { get }`
- `MockIdentity` — added `let nsec` constant (clearly fake value)

---

## [0.4.0] — 2026-04-24

### Added
- Screen 4 — Editor: full implementation replacing stub
- `TitleField` — styled display (last word in Instrument Serif italic) switches to plain TextField on tap; always in view hierarchy so focus is reliable
- `TagsRow` — inline tag entry; tap + to open TextField, Return/blur commits the tag
- `BodyField` — TextEditor with 1.6× line height, hidden scroll background
- `TodoSection` / `TodoRow` — checkbox toggle, editable text, Return adds next item, × button deletes
- `EditorTopBar` — back navigation, save-state indicator dot (animates on change), share + ellipsis stubs
- `EditorToolBar` — word count, heading / list / todo pill buttons
- Debounced autosave (400 ms) with animated save-state dot; explicit save on `onDisappear`
- New note lifecycle: insert into `modelContext` on compose, delete on back if still empty (`isNew` flag)

### Changed
- `Note` and `TodoItem` converted from structs to SwiftData `@Model final class`
- `@Relationship(deleteRule: .cascade)` on `Note.todos` — deleting a note removes its todo items
- `TimelineView` — `@State` seed data replaced with `@Query(sort: \Note.createdAt, order: .reverse)`; compose bar now inserts via `modelContext` and navigates with `navigationDestination(item:)`
- `EditorView` — `@State + onSave callback` pattern replaced with `@Bindable + modelContext.save()`
- `ContentView` — `@State var onboardingComplete` replaced with `@AppStorage("hasCompletedOnboarding")` so onboarding only shows on first launch

### Fixed
- App watchdog kill on first install: `ModelContainer` creation moved to `.task {}` after the launch window closes; `init()` now returns immediately
- `Library/Application Support` pre-created before container setup to avoid CoreData slow-recovery path
- `scenePhase → .background` triggers explicit `modelContext.save()` as safety net for force-quit scenarios
- Image icon removed from editor toolbar (was non-functional; moved to backlog)

---

## [0.3.0] — 2026-04-24

### Added
- Screen 3 — Search & Ask: overlay-based search (not a sheet) with dim backdrop and top-anchored card
- Live note filter across title, body, and tags
- Custom blinking caret in query bar (respects `accessibilityReduceMotion`)
- Action rows: "New note with this tag" and "See all in …"

### Changed
- Search presented as inline `.overlay` with fade transition — wireframe overrides spec sheet behaviour

---

## [0.2.0] — 2026-04-24

### Added
- Screen 2 — Timeline: day-grouped feed (Today / Yesterday / weekday / date), tag strip with in-place filtering, floating compose bar
- `TimelineHeader` with live date, NO.TE wordmark (tracking 0.8), search and settings icon tiles
- `TagStrip` — horizontal scroll, active tag underlined with 2pt ink bar
- `NoteRow` — 36pt time column, title + body + tags, 1pt rule dividers between rows within a group
- `TimelineComposeBar` — floating pill with compose shadow, mic icon, plus button
- 8 seeded mock notes spanning today, yesterday, and two older days
- `EditorView` stub (placeholder, full implementation in screen 4)
- `SearchView` stub (placeholder, full implementation in screen 3)
- `SettingsView` stub (placeholder, full implementation in screen 5)

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
