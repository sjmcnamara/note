import Foundation
import NostrSDK

/// Pure helper for validating an nsec string. Used by the Key Import flow
/// to derive the npub before the user confirms.
///
/// The actual write to Keychain happens in `IdentityService.importKey(nsec:)`.
enum NsecValidator {
    enum Result: Equatable {
        case empty
        case valid(npub: String, publicKeyHex: String)
        case invalid

        var isValid: Bool {
            if case .valid = self { return true }
            return false
        }
    }

    /// Validate a candidate nsec. Trims whitespace, parses with NostrSDK,
    /// and derives the npub. Returns `.empty` for blank input so the UI can
    /// distinguish "nothing typed yet" from "typed garbage".
    static func validate(_ input: String) -> Result {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }

        do {
            let keys = try Keys.parse(secretKey: trimmed)
            let npub = try keys.publicKey().toBech32()
            let pubHex = keys.publicKey().toHex()
            return .valid(npub: npub, publicKeyHex: pubHex)
        } catch {
            return .invalid
        }
    }
}
