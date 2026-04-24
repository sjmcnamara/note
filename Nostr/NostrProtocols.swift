import Foundation

/// Public-facing identity. The secret key (nsec) lives exclusively in the
/// Keychain, accessed via `IdentityService`.
struct NostrIdentity: Equatable {
    /// Full bech32-encoded public key ("npub1…").
    let npub: String
    /// Raw hex public key (used internally for event authoring).
    let publicKeyHex: String

    /// Abbreviated form for UI display ("npub1abc…wxyz").
    var shortNpub: String {
        guard npub.count > 16 else { return npub }
        return String(npub.prefix(12)) + "…" + String(npub.suffix(4))
    }
}

protocol NostrBackup: AnyObject {
    var status: BackupStatus { get }
    func publish(_ note: Note) async throws
    func restore(since: Date?) async throws -> [Note]
}
