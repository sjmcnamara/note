# Changelog

All notable changes to NO.TE are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

---

## [0.10.1] — 2026-04-27

### Fixed
- Editor body / phantom checklist bug: re-opening a note with multi-line body sometimes left the bottom half blank or showed an empty "To do" overlay. Two underlying causes addressed:
  - `BodyField` now uses `.scrollDisabled(true)` and a generous `minHeight: 360`, so the `TextEditor` grows with content inside the outer `ScrollView` instead of getting capped at 120pt and scrolling internally.
  - Empty `TodoItem`s are now pruned in `EditorView.onDisappear`, so a stray "Todo" toolbar tap doesn't haunt the next open as a blank checklist row.
- Title now strips newlines (Return + paste) and blurs focus on Return — no more multi-line titles. `lineLimit(1...3)` still allows visual wrapping for long titles.
- `addTodo()` skips inserting a new blank when the trailing todo is already empty (prevents stacking empties via repeated toolbar taps or Return-on-empty).

### Added
- Per-tag delete in the Editor: each tag chip now has a small `×` button that removes it from the note's tag array.

### Changed
- `MARKETING_VERSION` 0.10.1, `CURRENT_PROJECT_VERSION` 9.

---

## [0.10.0] — 2026-04-26

### Added
- Screen 9 — Tag filter: new `TagFilterView` reachable via tap on any tag chip in `TimelineView`
- 32pt Instrument Serif italic header of the tag name
- Meta line: `N notes · since <d MMMM> · rename` (rename underlined, opens an inline `Alert` with a `TextField`; saving rewrites the tag across all matching notes and pops back)
- Related-tag strip ("often with: …") — top 6 co-occurring tags by frequency, tap pushes a nested `TagFilterView`
- Week-grouped feed: `This week`, `Last week`, then month name (or `MMMM yyyy` for older years). Swipe-to-delete on rows
- `⋯` menu offers Rename and Delete tag (confirmation dialog; Delete tag strips the label from every note but preserves their content)
- `@Query(filter:)` uses `#Predicate { $0.tags.contains(tag) }` so the filter runs in SwiftData

### Changed
- `MARKETING_VERSION` 0.10.0, `CURRENT_PROJECT_VERSION` 8
- `TimelineView`'s `TagStrip` simplified: tap pushes to `TagFilterView`. The inline tap-to-filter behaviour and the `all` reset chip are gone — `TagFilterView` is the dedicated tag view and Search handles ad-hoc filtering. May revisit on real-device testing.

---

## [0.9.0] — 2026-04-25

### Added
- Screen 8 — Empty state: `EmptyTimelineView` shown by `TimelineView` when `notes.isEmpty`
- Centered hero (10pt ink dot above "A quiet place, ready." with "ready." in Instrument Serif italic 24pt) + sub-copy + two bordered CTAs (Start a note, Record a voice memo)
- Start a note → calls existing `createNote` flow (insert + push EditorView)
- Record a voice memo → transient toast stub ("Voice memos land later.") — full recording + transcription flow deferred
- TimelineHeader stays visible; TagStrip is hidden in the empty state (nothing to filter)
- TimelineComposeBar still floats at the bottom

### Changed
- `MARKETING_VERSION` 0.9.0, `CURRENT_PROJECT_VERSION` 7

---

## [0.8.1] — 2026-04-25

### Fixed
- Key import: tapping "Use this key" left the user stuck on `KeyImportView` even though the identity was replaced. `dismiss()` from `AdvancedSetupView`'s level was a no-op while `KeyImportView` was on top. `KeyImportView` now dismisses itself first, then defers the parent's `onImported` callback by ~350 ms so the navigation chain unwinds cleanly back to `AdvancedSettingsView`.

### Added
- `AdvancedSettingsView` shows a transient "Identity updated" toast when the npub changes mid-session (covers both Generate and Import flows). Baseline npub captured on first appear; toast only fires on subsequent changes.

### Changed
- `MARKETING_VERSION` 0.8.1, `CURRENT_PROJECT_VERSION` 6.

---

## [0.8.0] — 2026-04-25

### Added
- Screen 7 — Key import: full implementation replacing stub
- `NsecValidator` — pure helper that trims input, parses with `Keys.parse(secretKey:)`, and returns `.empty / .valid(npub:publicKeyHex:) / .invalid`. Used by the import flow to derive npub before commit.
- `KeyImportView`: paste field (monospace 13pt, multi-line), "or" divider, QR scan row (toast stub), `DerivedKeyCard` revealed on valid input with avatar + npub + green-dot "Key is valid", inline note on invalid input. Bottom action bar: Cancel + Use this key (filled, disabled until valid). 180ms debounce on validation.
- Confirm path calls `IdentityService.importKey(nsec:)` and propagates back through Advanced setup's completion callback (same chain as Generate).
- **First test target.** `NOTETests` bundle with `NsecValidatorTests` covering empty / valid / whitespace-tolerant / npub-instead-of-nsec / garbled / truncated / `isValid` helper. Tests use `Keys.generate()` to round-trip rather than hard-coded vectors.

### Changed
- `MARKETING_VERSION` 0.8.0, `CURRENT_PROJECT_VERSION` 5.

---

## [0.7.0] — 2026-04-24

### Added
- **Real Nostr identity.** First non-UI release. Replaces `MockIdentity` with a real keypair generated via [`rust-nostr/nostr-sdk-swift`](https://github.com/rust-nostr/nostr-sdk-swift) (pinned `from: 0.44.2`).
- `IdentityService` — `@MainActor ObservableObject` that auto-generates a keypair on first launch (Rust FFI runs off main to keep the splash responsive), parses the stored nsec on subsequent launches, and exposes `regenerate()`, `importKey(nsec:)`, and `exportNsec()` for user-initiated flows. Injected app-wide via `@EnvironmentObject`.
- `KeychainService` + `SecureStorage` protocol ported (trimmed) from `whistle`. nsec stored with `kSecAttrAccessibleWhenUnlocked`, Keychain-only (no UserDefaults fallback). `InMemorySecureStorage` included for previews/tests.
- Advanced setup → Generate now actually destroys the current key and mints a new pair (via `IdentityService.regenerate()`), success haptic, dismiss.
- Settings → Advanced → nsec Reveal reads the real bech32 nsec from Keychain via `IdentityService.exportNsec()` after FaceID challenge; auto-hides after 30 s as before.

### Changed
- `NostrIdentity` converted from protocol to public struct (`npub` + `publicKeyHex` only). The secret key never appears on the identity object — it lives only in Keychain.
- `UnsignedEvent` / `SignedEvent` / `signEvent(_:)` removed. Event signing will come from `nostr-sdk-swift`'s `Keys` when we publish.
- `MockIdentity` removed. Previews use `NostrIdentity.preview` or `IdentityService(storage: InMemorySecureStorage())`.
- Onboarding "Start writing" no longer calls a mock generator — identity is created at app init.
- README stack line updated; `MARKETING_VERSION` 0.7.0, `CURRENT_PROJECT_VERSION` 4.

### Notes
- Regenerating keys from Settings is destructive and currently one-tap — a confirm dialog is worth a follow-up.
- Bech32 validator + tests still land with Screen 7 (Key import).

---

## [0.6.0] — 2026-04-24

### Added
- Screen 6 — Advanced setup: full implementation replacing stub
- Hero (`Bring your own keys.` with italic serif on "own keys."), sub-copy, three bordered option cards (Generate / Import / Restore), footer with privacy line + Nostr credit
- Recommended variant on Generate row — 1.5pt `noteInk` border and `recommended` badge
- Generate row calls `MockIdentity.generate()`, triggers `.success` haptic, and dismisses (or runs onboarding `onComplete` if invoked from onboarding)
- Restore row shows transient toast — full flow lands with real Nostr later
- `KeyImportView` stub created so the Import row has a destination; full Screen 7 to come
- Onboarding gains secondary "Advanced setup" underline link → sheet-presents `AdvancedSetupView` inside its own `NavigationStack`

### Changed
- `MARKETING_VERSION` 0.6.0 / `CURRENT_PROJECT_VERSION` 3

---

## [0.5.2] — 2026-04-24

### Added
- Swipe-to-delete on timeline rows — trailing `.swipeActions` with `allowsFullSwipe`; tap the trash, or full-swipe, to delete. Animation on removal.

### Changed
- Timeline switched from `LazyVStack` + custom `DaySection` to plain `List` with `Section` headers. Row background, separator tint (`Color.noteRule`), and separator leading inset (24pt) overridden so the custom look is preserved.
- Onboarding footer copy: "Built on Nostr." → "Built on Nostr. An open protocol."
- About footer copy: "Powered by Nostr · open protocol" → "Built on Nostr. An open protocol."
- `MARKETING_VERSION` bumped to 0.5.2, `CURRENT_PROJECT_VERSION` to 2.

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
