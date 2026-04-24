import Foundation
import Observation

@Observable
final class MockBackup: NostrBackup {
    var status: BackupStatus = .disabled

    func publish(_ note: Note) async throws {
        status = .syncing
        try await Task.sleep(for: .milliseconds(300))
        status = .synced(lastAt: Date())
    }

    func restore(since: Date?) async throws -> [Note] {
        []
    }
}

// MARK: - Preview helpers

extension NostrIdentity {
    /// Fake identity for SwiftUI previews. Never used at runtime.
    static let preview = NostrIdentity(
        npub: "npub1preview0000000000000000000000000000000000000000000000000000",
        publicKeyHex: "preview00000000000000000000000000000000000000000000000000000000"
    )
}
