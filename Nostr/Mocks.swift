import Foundation
import Observation

struct MockIdentity: NostrIdentity {
    let npub = "npub1mock00000000000000000000000000000000000000000000000000000000"

    static func generate() -> MockIdentity { MockIdentity() }

    func signEvent(_ event: UnsignedEvent) throws -> SignedEvent {
        SignedEvent(
            id: UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: ""),
            pubkey: npub,
            createdAt: event.createdAt,
            kind: event.kind,
            tags: event.tags,
            content: event.content,
            sig: "mocksig\(UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: ""))"
        )
    }
}

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
