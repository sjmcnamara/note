# NO.TE — Roadmap

Build order follows `handoff_claude_code/PROMPTS.md`. One screen per PR. Real Nostr comes last.

---

## Done

### [0.1.0] Bootstrap
- xcodegen project scaffold
- Design tokens: color assets (light + dark), `NoteFont`, `Space`, `Radius`, shadow helpers, `Motion`
- Inter Tight + Instrument Serif Italic registered
- `NostrIdentity` and `NostrBackup` protocol stubs
- `MockIdentity` and `MockBackup` for UI-only development

### [0.1.1] Onboarding fixes
- Full-screen background on iOS 17+
- Flattened project structure

### [0.2.0] Screen 2 — Timeline
- Day-grouped feed, tag strip, note rows, floating compose bar
- Stub views for Editor, Search, Settings

### [0.3.0] Screen 3 — Search & Ask
- Overlay-based search (not sheet) with dim backdrop, top-anchored card
- Live filter across title, body, and tags
- Blinking 2pt caret in query bar (1 Hz, off under Reduce Motion)
- Action rows: "New note with this tag", "See all in …"
- AI answer block removed — local search only for now

### [0.4.0] Screen 4 — Editor + SwiftData persistence
- Full editor: title (last word in Instrument Serif italic), body, tags, todos
- Saved dot pulsing on 400ms debounced write
- Todo: checkbox toggle, Return adds next item, × deletes
- Tags: inline entry on + tap, Return/blur commits
- SwiftData: `Note` and `TodoItem` as `@Model` classes, cascade delete
- `@Query` replaces seed data in Timeline; compose inserts into modelContext
- `@AppStorage` onboarding flag — shows once, then opens straight to Timeline
- First-run fix: store created in `.task` after launch window, explicit URL,
  `cloudKitDatabase: .none` — tested fast on Release build

### [0.5.0] Screen 5 — Settings
- Identity card: avatar (conic gradient from npub), npub copy chip, FaceID-gated nsec reveal (30s auto-hide), "Back up now" footer link
- Appearance picker: Light / Night / System tiles, active tile 2pt ink border, `@AppStorage("appearance")` → `preferredColorScheme` applied globally in ContentView
- Plain ruled rows: Text size (−/+), Tag suggestions, Morning prompt
- Private Backup card: shield icon, E2EE badge, toggle simulates connecting/synced, relay row with halo dot, Add relay + Restore outline buttons (stubbed)
- Footer wordmark: "NO.TE · Powered by Nostr · open protocol"
- `NostrIdentity` protocol and `MockIdentity` extended with `nsec`
- `NSFaceIDUsageDescription` added to project

### [0.5.2] Swipe-to-delete + copy tweaks
- Timeline rows now support swipe-to-delete via `List` + `.swipeActions` (allowsFullSwipe). Replaces `LazyVStack` with a styled plain `List` keeping row background, separator tint, and leading inset consistent with the previous design.
- Nostr credit copy unified across Onboarding and About to "Built on Nostr. An open protocol."
- Version bumped to 0.5.2 / build 2.

### [0.5.1] Settings restructure — Basic / Advanced / About
- `SettingsView` slimmed to Basic: Appearance picker, Text size slider (7 unique-labelled steps), two nav rows (About, Advanced)
- `AboutView` new: version + build from `Bundle.main`, NO.TE wordmark, "Powered by Nostr" credit
- `AdvancedSettingsView` new: Identity card, Private Backup card, Change keys / Restore rows (link to `AdvancedSetupView`)
- All `NoteFont` tokens now use `relativeTo:` and the app applies `.dynamicTypeSize(...)` at `ContentView`, so every text element scales with the slider
- Dropped `Tag suggestions` and `Morning prompt` toggles (no design, no implementation)
- `MARKETING_VERSION` + `CURRENT_PROJECT_VERSION` added to `project.yml`

---

### [0.6.0] Screen 6 — Advanced setup
- Full implementation replacing stub: hero with italic serif on "own keys.", sub-copy, 3 bordered option cards, privacy + Nostr credit footer
- `Generate` → `MockIdentity.generate()` + success haptic + dismiss (or onboarding onComplete)
- `Import existing nsec` → pushes new `KeyImportView` stub (Screen 7 to come)
- `Restore from backup` → transient toast ("Restore flow lands with real Nostr.")
- Recommended variant on Generate: 1.5pt `noteInk` border + `recommended` badge
- Onboarding gains secondary "Advanced setup" link → sheet-presents `AdvancedSetupView` in its own NavigationStack

### [0.7.0] Real Nostr identity
- First non-UI release. Adds `rust-nostr/nostr-sdk-swift` (`from: 0.44.2`) as SPM dep
- `IdentityService` (`@MainActor ObservableObject`) — auto-generates on first launch, parses stored nsec thereafter. Rust FFI runs off main on cold start
- `KeychainService` + `SecureStorage` protocol (ported from whistle, trimmed) — nsec stored Keychain-only, `kSecAttrAccessibleWhenUnlocked`
- `NostrIdentity` turned from protocol into public struct (npub + publicKeyHex). nsec never on the identity object
- Advanced setup → Generate now actually mints a fresh keypair and overwrites the Keychain entry
- Settings → Advanced → nsec Reveal reads real bech32 nsec from Keychain after FaceID, auto-hides after 30 s
- Removed: `MockIdentity`, `UnsignedEvent`, `SignedEvent`, unused `signEvent(_:)`
- Open: regenerate confirm dialog (deferred until first export path lands)

### [0.8.0] Screen 7 — Key import
- Full implementation replacing stub: monospace paste field, "or" divider, QR scan row (toast stub), `DerivedKeyCard` on valid input, bottom Cancel + Use this key actions
- `NsecValidator` pure helper — trims input, parses with NostrSDK, returns `.empty / .valid / .invalid` with derived npub + pubkey hex
- 180 ms debounce on validation as the user types/pastes
- Confirm path: `IdentityService.importKey(nsec:)` → propagates back through Advanced setup's completion callback (same as Generate)
- **First test target.** `NOTETests` bundle (added to `project.yml`) with `NsecValidatorTests` covering empty / valid / whitespace / npub-as-nsec / garbled / truncated. Tests round-trip via `Keys.generate()` rather than hard-coded vectors.

### [0.8.1] Key import nav fix + identity-updated toast
- Fix: tapping "Use this key" replaced the identity but left the user on `KeyImportView`. `KeyImportView` now dismisses itself first, then defers `onImported` by ~350 ms so the chain unwinds back through `AdvancedSetupView` to `AdvancedSettingsView`.
- `AdvancedSettingsView` shows a transient "Identity updated" toast when the npub changes mid-session — covers both Generate and Import flows.

### [0.9.0] Screen 8 — Empty state
- `EmptyTimelineView` shown by `TimelineView` when `notes.isEmpty`. Header + compose bar stay visible; TagStrip hidden.
- Centered hero (10pt ink dot + "A quiet place, **ready.**" with the last word in Instrument Serif italic), sub-copy, two bordered CTAs.
- Start a note → existing `createNote` flow. Record a voice memo → toast stub (full recording + transcription deferred).

### [0.10.0] Screen 9 — Tag filter
- New `TagFilterView` reachable via tap on any TagStrip chip in Timeline. Inline tap-to-filter and the `all` reset chip removed; `TagFilterView` covers that ground and Search handles free-text filtering.
- 32pt Instrument Serif italic header, meta `"N notes · since <date> · rename"`, "often with:" related-tag strip (top 6 by co-occurrence)
- Week-grouped feed: `This week` / `Last week` / month name. Swipe-to-delete rows
- `⋯` menu: Rename (Alert + TextField, rewrites globally + pops back) and Delete tag (confirmation dialog, strips the label from every note)
- `@Query(filter:)` with `#Predicate { $0.tags.contains(tag) }` — filtering happens in SwiftData
- Open: rename republishing affected notes once real backup lands, merge-into-other-tag flow (deferred), revisit tap-vs-long-press once a real device is available

### [0.10.1] Editor bug-fix patch
- Fix: `BodyField` capped at 120pt inside an outer `ScrollView`, so re-opening a multi-line note clipped content. Now `scrollDisabled(true)` + `minHeight: 360`.
- Fix: phantom blank checklist after a stray Todo toolbar tap. Empty `TodoItem`s are pruned on `onDisappear`; `addTodo()` no longer stacks empties.
- Fix: title accepted Return / multi-line input. Newlines are now stripped and focus drops on Return. Visual wrap kept (lineLimit 1...3).
- Per-tag delete in the Editor — small `×` on each tag chip.

### [0.12.0] Editor rev 2 — formatting toolbar, markdown preview, tag collapse
- `ToolbarItemGroup(placement: .keyboard)`: B / I / H1 / H2 / bullet / todo buttons + word count, pinned above keyboard
- Read/edit markdown preview toggle (eye icon in top bar) using `Text(AttributedString(markdown:))`
- Tag collapse: >4 tags → show first 4 + "…+N" expand chip
- Removed static bottom `EditorToolBar`

### [0.11.0] DevEx — CI, scripts, more tests
- CI ported from `whistle`: `ci.yml` (iOS build+test, SwiftLint, dependency review), `codeql.yml` (Swift, weekly), `scorecard.yml` (OpenSSF, weekly)
- `scripts/build.sh` mirrors CI locally (`build` / `test` / `clean`)
- `.swiftlint.yml` lenient starter; README gains CI/CodeQL/Scorecard/iOS-coverage badges
- `makeGroups` / `makeWeekGroups` extracted to a new `Domain/` source folder, both with injectable `now` so tests pin time
- Unit tests grow from 7 → 30 across `IdentityServiceTests`, `TimelineGroupingTests`, `TagWeekGroupingTests`, `NoteModelTests`, plus existing `NsecValidatorTests`

---

## Up next

### [0.13.0] App lock (FaceID gate)
- Port `AppLockService` from whistle — biometric-first with device-passcode fallback
- "Lock with FaceID" toggle in Basic Settings (default OFF)
- Lock overlay at `ContentView` root; blocks until `evaluatePolicy` succeeds

### [0.14.0] Architecture review (doc)
- `docs/architecture/backup.md` — compare relay vs file-export vs hybrid; land a decision

### Screen 10 — Share & export
- Bottom sheet from Editor share icon
- .txt and .md export with real file writers
- Signed Nostr event stub (dummy JSON until NIP-44)
- Private link copies `https://no.te/v/<uuid>` to clipboard

### Screen 11 — Night mode audit
- Confirm every Color routes through palette assets
- Test all screens in dark mode
- Adjust shadow opacities per spec

---

## Later — Real Nostr

Split across multiple PRs, feature-flagged:

1. `KeychainIdentity` replacing `MockIdentity`
2. `RelayBackup` replacing `MockBackup`
3. NIP-44 v2 encryption round-trip with test vectors
4. Single-relay WebSocket client with exponential backoff
5. Publish + subscribe + local reconciliation

Default relay: `wss://relay.pub`. nsec never logged. TLS-only (reject non-wss).
