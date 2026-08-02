import XCTest
@testable import NOTE

final class VoiceNotesTests: XCTestCase {

    // MARK: - Duration formatting

    func test_formatDuration_zero() {
        XCTAssertEqual(VoiceNotes.formatDuration(0), "0:00")
    }

    func test_formatDuration_underAMinute() {
        XCTAssertEqual(VoiceNotes.formatDuration(7), "0:07")
        XCTAssertEqual(VoiceNotes.formatDuration(42), "0:42")
    }

    func test_formatDuration_overAMinute() {
        XCTAssertEqual(VoiceNotes.formatDuration(61), "1:01")
        XCTAssertEqual(VoiceNotes.formatDuration(725), "12:05")
    }

    func test_formatDuration_roundsFractionalSeconds() {
        XCTAssertEqual(VoiceNotes.formatDuration(41.6), "0:42")
        XCTAssertEqual(VoiceNotes.formatDuration(41.4), "0:41")
    }

    func test_formatDuration_negativeClampsToZero() {
        XCTAssertEqual(VoiceNotes.formatDuration(-5), "0:00")
    }

    // MARK: - Files

    func test_newFileName_isUniqueM4a() {
        let one = VoiceNotes.newFileName()
        let two = VoiceNotes.newFileName()
        XCTAssertTrue(one.hasSuffix(".m4a"))
        XCTAssertNotEqual(one, two)
    }

    func test_url_livesInVoiceNotesDirectory() {
        let url = VoiceNotes.url(for: "abc.m4a")
        XCTAssertEqual(url.lastPathComponent, "abc.m4a")
        XCTAssertEqual(url.deletingLastPathComponent().lastPathComponent, "VoiceNotes")
    }

    func test_deleteAudio_removesFileAndTolerantOfMissing() throws {
        let name = VoiceNotes.newFileName()
        let url = VoiceNotes.url(for: name)
        try Data("test".utf8).write(to: url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        let note = Note(title: "Voice note", audioFile: name, audioDuration: 1)
        VoiceNotes.deleteAudio(for: note)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))

        VoiceNotes.deleteAudio(for: note) // second call is a no-op
        VoiceNotes.deleteAudio(for: Note(title: "no audio")) // nil audioFile is a no-op
    }

    // MARK: - Model

    func test_note_audioFieldsDefaultToNil() {
        let note = Note(title: "plain")
        XCTAssertNil(note.audioFile)
        XCTAssertNil(note.audioDuration)
    }
}
