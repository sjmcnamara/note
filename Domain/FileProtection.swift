import Foundation

/// Applies iOS Data Protection to files NO.TE writes outside the Keychain
/// (the SwiftData store, voice note recordings). Everything on-device gets
/// the default `.completeUntilFirstUserAuthentication` unless told otherwise
/// — readable in the background any time after the first unlock since boot.
enum FileProtection {

    /// `.completeUnlessOpen`, not `.complete`: both encrypt the file while
    /// the device is locked, but `.complete` also revokes access to an
    /// already-open file descriptor the instant the device locks — which
    /// would kill an in-progress SwiftData write or a live recording.
    /// `.completeUnlessOpen` only encrypts once the file is closed, so an
    /// open write session rides out a lock uninterrupted.
    static func apply(to url: URL, level: FileProtectionType = .completeUnlessOpen) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try? FileManager.default.setAttributes([.protectionKey: level], ofItemAtPath: url.path)
    }
}
