import Foundation

/// File management + formatting helpers for voice note audio. Recordings
/// live in Documents/VoiceNotes as .m4a files; notes store just the filename.
enum VoiceNotes {

    static var directory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VoiceNotes", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    static func newFileName() -> String {
        "\(UUID().uuidString).m4a"
    }

    static func url(for fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }

    /// Removes the audio file backing a note, if any. Call before deleting
    /// the note itself — SwiftData won't clean up files on disk.
    static func deleteAudio(for note: Note) {
        guard let fileName = note.audioFile else { return }
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    /// "0:07", "1:42", "12:05" — minutes never padded, seconds always.
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
