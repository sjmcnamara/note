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

---

## Up next

### Screen 3 — Search & Ask
- Sheet from search icon
- Local filter against mock notes
- Blinking 2pt caret after query text (1Hz, off under Reduce Motion)
- Mock AI answer (400ms delay, canned text)
- Action rows with small icon tiles

### Screen 4 — Editor
- Bindable `Note`, title + body fields
- One italic serif word in title
- Ghost pill toolbar (heading, list, todo, image)
- Saved dot pulsing on debounced local write (400ms)
- AI margin note pill at bottom of body

### Screen 5 — Settings
- Identity card: npub + hidden nsec + FaceID-gated Reveal (auto-hide 30s)
- Appearance picker (Light / Night / System)
- Plain ruled rows section
- Private Backup card bound to `NostrBackup.status`
- Footer wordmark
- nsec must never be logged

### Screen 6 — Advanced setup
- Three options: Generate (recommended), Import nsec, Restore from backup
- Italic serif moment on "own keys."
- Generate → `MockIdentity.generate()` → dismiss
- Import → push `KeyImportView`
- Restore → stub toast

### Screen 7 — Key import
- Paste field with monospace text + blinking caret
- QR row → placeholder scanner
- `DerivedKeyCard` appears on valid input only
- bech32 parse + checksum validation
- Unit tests for the validator (required before shipping)

### Screen 8 — Empty state
- `EmptyTimelineView` when note count == 0
- Compose bar still floating
- Hero "A quiet place, ready." with "ready." in italic serif
- Two CTA rows: Start a note, Record a voice memo

### Screen 9 — Tag filter
- Pushed from long-press on a tag or Search's "See all in …" row
- Big italic serif tag name header
- Related tag strip inline
- Feed grouped by week
- Rename applies globally; triggers republish if backup on (no-op with MockBackup)

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
