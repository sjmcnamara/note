import Foundation
import SwiftData

@Model final class TodoItem {
    var id: UUID
    var text: String
    var done: Bool

    init(text: String, done: Bool = false) {
        self.id = UUID()
        self.text = text
        self.done = done
    }
}

@Model final class Note {
    var id: UUID
    var title: String
    var body: String
    var tags: [String]
    @Relationship(deleteRule: .cascade) var todos: [TodoItem]
    var createdAt: Date
    var updatedAt: Date

    init(
        title: String,
        body: String = "",
        tags: [String] = [],
        todos: [TodoItem] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = UUID()
        self.title = title
        self.body = body
        self.tags = tags
        self.todos = todos
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
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
