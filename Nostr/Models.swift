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
    // Voice note attachment: filename inside VoiceNotes.directory + length
    // in seconds. Optional with defaults so existing stores migrate lightly.
    var audioFile: String?
    var audioDuration: Double?

    init(
        title: String,
        body: String = "",
        tags: [String] = [],
        todos: [TodoItem] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        audioFile: String? = nil,
        audioDuration: Double? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.body = body
        self.tags = tags
        self.todos = todos
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.audioFile = audioFile
        self.audioDuration = audioDuration
    }
}

enum BackupStatus {
    case disabled
    case connecting
    case syncing
    case synced(lastAt: Date)
    case error(String)
}
