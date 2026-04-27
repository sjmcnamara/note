import XCTest
import NostrSDK
@testable import NOTE

@MainActor
final class IdentityServiceTests: XCTestCase {

    func test_initialise_freshStorage_generatesIdentityAndPersistsNsec() async {
        let storage = InMemorySecureStorage()
        let svc = IdentityService(storage: storage)

        XCTAssertNil(svc.identity)
        XCTAssertNil(storage.load(key: .nsec))

        await svc.initialise()

        XCTAssertNotNil(svc.identity)
        XCTAssertTrue(svc.identity?.npub.hasPrefix("npub1") == true)
        XCTAssertEqual(svc.isNewUser, true)
        XCTAssertNotNil(storage.load(key: .nsec))
        XCTAssertTrue(storage.load(key: .nsec)?.hasPrefix("nsec1") == true)
    }

    func test_initialise_existingNsec_restoresWithoutMintingNew() async throws {
        let keys = Keys.generate()
        let nsec = try keys.secretKey().toBech32()
        let expectedNpub = try keys.publicKey().toBech32()

        let storage = InMemorySecureStorage()
        storage.save(key: .nsec, value: nsec)

        let svc = IdentityService(storage: storage)
        await svc.initialise()

        XCTAssertEqual(svc.identity?.npub, expectedNpub)
        XCTAssertEqual(svc.isNewUser, false)
    }

    func test_regenerate_replacesIdentityAndOverwritesKeychain() async {
        let storage = InMemorySecureStorage()
        let svc = IdentityService(storage: storage)
        await svc.initialise()

        let originalNpub = svc.identity?.npub
        let originalNsec = storage.load(key: .nsec)
        XCTAssertNotNil(originalNpub)

        await svc.regenerate()

        XCTAssertNotNil(svc.identity)
        XCTAssertNotEqual(svc.identity?.npub, originalNpub, "regenerate should produce a different npub")
        XCTAssertNotEqual(storage.load(key: .nsec), originalNsec, "Keychain nsec should be overwritten")
        XCTAssertEqual(svc.isNewUser, false)
    }

    func test_importKey_validNsec_replacesIdentity() async throws {
        let svc = IdentityService(storage: InMemorySecureStorage())
        await svc.initialise()

        let foreign = Keys.generate()
        let foreignNsec = try foreign.secretKey().toBech32()
        let foreignNpub = try foreign.publicKey().toBech32()

        try svc.importKey(nsec: foreignNsec)

        XCTAssertEqual(svc.identity?.npub, foreignNpub)
        XCTAssertEqual(svc.isNewUser, false)
    }

    func test_importKey_invalidNsec_throwsAndPreservesIdentity() async {
        let svc = IdentityService(storage: InMemorySecureStorage())
        await svc.initialise()
        let preserved = svc.identity?.npub

        XCTAssertThrowsError(try svc.importKey(nsec: "not a real nsec"))
        XCTAssertEqual(svc.identity?.npub, preserved, "Failed import must not clobber the existing identity")
    }

    func test_exportNsec_returnsStoredValue() async {
        let storage = InMemorySecureStorage()
        let svc = IdentityService(storage: storage)
        await svc.initialise()

        XCTAssertEqual(svc.exportNsec(), storage.load(key: .nsec))
    }
}
