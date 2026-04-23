import Foundation

struct TodoItem: Identifiable, Equatable {
    var id = UUID()
    var text: String
    var done: Bool = false
}

struct Note: Identifiable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var tags: [String]
    var todos: [TodoItem] = []
    var createdAt: Date
    var updatedAt: Date
}

enum BackupStatus {
    case disabled
    case connecting
    case syncing
    case synced(lastAt: Date)
    case error(String)
}

struct UnsignedEvent {
    let kind: Int
    let pubkey: String
    let createdAt: Date
    let tags: [[String]]
    let content: String
}

struct SignedEvent {
    let id: String
    let pubkey: String
    let createdAt: Date
    let kind: Int
    let tags: [[String]]
    let content: String
    let sig: String
}
