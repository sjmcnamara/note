import Foundation
import NostrSDK

/// Manages the user's Nostr identity.
///
/// On first launch a keypair is generated and the nsec is stored via `storage`.
/// On subsequent launches the stored nsec is parsed and the `Keys` object is
/// reconstructed. The nsec is never exposed outside this class except via
/// `exportNsec()` for user-initiated reveal.
@MainActor
final class IdentityService: ObservableObject {
    @Published private(set) var identity: NostrIdentity?
    @Published private(set) var isNewUser = false

    /// Live NostrSDK `Keys` — used by event signing and relay modules.
    private(set) var keys: Keys?

    private let storage: SecureStorage

    init(storage: SecureStorage = KeychainService.shared) {
        self.storage = storage
    }

    // MARK: - Lifecycle

    /// Load stored keys or generate a new pair. Runs Rust FFI work on a
    /// background queue so the splash screen stays responsive on cold start.
    func initialise() async {
        typealias Result = (keys: Keys, npub: String, pubHex: String, isNew: Bool)
        let storage = self.storage

        let result: Result? = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                if let nsec = storage.load(key: .nsec),
                   let restored = try? Keys.parse(secretKey: nsec),
                   let npub = try? restored.publicKey().toBech32() {
                    let pubHex = restored.publicKey().toHex()
                    continuation.resume(returning: (restored, npub, pubHex, false))
                    return
                }

                let newKeys = Keys.generate()
                guard let nsec = try? newKeys.secretKey().toBech32(),
                      let npub = try? newKeys.publicKey().toBech32() else {
                    continuation.resume(returning: nil)
                    return
                }
                let pubHex = newKeys.publicKey().toHex()
                storage.save(key: .nsec, value: nsec)
                continuation.resume(returning: (newKeys, npub, pubHex, true))
            }
        }

        guard let result else { return }
        self.keys = result.keys
        self.identity = NostrIdentity(npub: result.npub, publicKeyHex: result.pubHex)
        self.isNewUser = result.isNew
    }

    // MARK: - Mutations

    /// Destroy the current key and generate a new pair. Used by the "Generate
    /// new keys" action in Advanced setup. Runs on a background queue.
    func regenerate() async {
        let storage = self.storage

        let result: (Keys, String, String)? = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                storage.delete(key: .nsec)
                let newKeys = Keys.generate()
                guard let nsec = try? newKeys.secretKey().toBech32(),
                      let npub = try? newKeys.publicKey().toBech32() else {
                    continuation.resume(returning: nil)
                    return
                }
                let pubHex = newKeys.publicKey().toHex()
                storage.save(key: .nsec, value: nsec)
                continuation.resume(returning: (newKeys, npub, pubHex))
            }
        }

        guard let (newKeys, npub, pubHex) = result else { return }
        self.keys = newKeys
        self.identity = NostrIdentity(npub: npub, publicKeyHex: pubHex)
        self.isNewUser = false
    }

    /// Replace current keys with an imported nsec. Throws if the key is invalid.
    func importKey(nsec: String) throws {
        let imported = try Keys.parse(secretKey: nsec)
        let npub = try imported.publicKey().toBech32()
        let pubHex = imported.publicKey().toHex()

        storage.save(key: .nsec, value: nsec)
        self.keys = imported
        self.identity = NostrIdentity(npub: npub, publicKeyHex: pubHex)
        self.isNewUser = false
    }

    // MARK: - Reveal

    /// Returns the stored nsec for user-initiated reveal (FaceID-gated in UI).
    /// Not exposed to any non-UI caller.
    func exportNsec() -> String? {
        storage.load(key: .nsec)
    }
}
