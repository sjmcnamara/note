import XCTest
import NostrSDK
@testable import NOTE

final class NsecValidatorTests: XCTestCase {

    func test_emptyInput_returnsEmpty() {
        XCTAssertEqual(NsecValidator.validate(""), .empty)
        XCTAssertEqual(NsecValidator.validate("   "), .empty)
        XCTAssertEqual(NsecValidator.validate("\n\t"), .empty)
    }

    func test_validNsec_roundTripsThroughValidator() throws {
        // Generate a real keypair via NostrSDK so the test isn't tied to a
        // hard-coded vector that could drift if the upstream encoding changes.
        let keys = Keys.generate()
        let nsec = try keys.secretKey().toBech32()
        let expectedNpub = try keys.publicKey().toBech32()
        let expectedHex = keys.publicKey().toHex()

        let result = NsecValidator.validate(nsec)
        XCTAssertEqual(result, .valid(npub: expectedNpub, publicKeyHex: expectedHex))
        XCTAssertTrue(result.isValid)
    }

    func test_validNsec_withSurroundingWhitespace_isAccepted() throws {
        let keys = Keys.generate()
        let nsec = try keys.secretKey().toBech32()
        let padded = "  \(nsec)\n"

        XCTAssertTrue(NsecValidator.validate(padded).isValid)
    }

    func test_npubInsteadOfNsec_isInvalid() throws {
        let keys = Keys.generate()
        let npub = try keys.publicKey().toBech32()

        XCTAssertEqual(NsecValidator.validate(npub), .invalid)
    }

    func test_garbledBech32_isInvalid() {
        XCTAssertEqual(NsecValidator.validate("nsec1notarealkey"), .invalid)
        XCTAssertEqual(NsecValidator.validate("notbech32atall"), .invalid)
    }

    func test_truncatedNsec_isInvalid() throws {
        let keys = Keys.generate()
        let nsec = try keys.secretKey().toBech32()
        let truncated = String(nsec.dropLast(5))

        XCTAssertEqual(NsecValidator.validate(truncated), .invalid)
    }

    func test_isValid_helper() {
        XCTAssertFalse(NsecValidator.Result.empty.isValid)
        XCTAssertFalse(NsecValidator.Result.invalid.isValid)
        XCTAssertTrue(NsecValidator.Result.valid(npub: "x", publicKeyHex: "y").isValid)
    }
}
