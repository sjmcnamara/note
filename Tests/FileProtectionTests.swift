import XCTest
@testable import NOTE

// The Simulator has no Secure Enclave, so it doesn't implement Data
// Protection classes: `setAttributes(.protectionKey:)` never throws there,
// but reading the attribute back always yields nil regardless of what was
// set — on any file, in any directory. These tests can only verify apply()
// runs its write path without crashing; the actual protection guarantee
// only holds on-device and isn't something CI can assert.
final class FileProtectionTests: XCTestCase {

    private func tempFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).txt")
        try Data("test".utf8).write(to: url)
        return url
    }

    func test_apply_existingFile_doesNotThrowOrCrash() throws {
        let url = try tempFile()
        defer { try? FileManager.default.removeItem(at: url) }

        FileProtection.apply(to: url)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func test_apply_acceptsExplicitLevel() throws {
        let url = try tempFile()
        defer { try? FileManager.default.removeItem(at: url) }

        FileProtection.apply(to: url, level: .complete)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func test_apply_missingFile_isNoOp() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("does-not-exist.txt")
        FileProtection.apply(to: url) // must not throw or crash
    }
}
