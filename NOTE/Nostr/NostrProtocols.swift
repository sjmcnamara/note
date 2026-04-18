import Foundation

protocol NostrIdentity {
    var npub: String { get }
    func signEvent(_ event: UnsignedEvent) throws -> SignedEvent
}

protocol NostrBackup: AnyObject {
    var status: BackupStatus { get }
    func publish(_ note: Note) async throws
    func restore(since: Date?) async throws -> [Note]
}
