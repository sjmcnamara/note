import XCTest
import SwiftData
@testable import NOTE

@MainActor
final class TagWeekGroupingTests: XCTestCase {

    // Anchor "now" to Wednesday 2026-04-15 12:00 UTC. Calendar's week-of-year
    // starts on Sunday by default in en_US — that's the locale CI runs in.
    private let now: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 4; c.day = 15; c.hour = 12; c.minute = 0
        c.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: c)!
    }()

    private var container: ModelContainer!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Note.self, TodoItem.self, configurations: config)
    }

    override func tearDown() {
        container = nil
    }

    private func makeNote(at offsetDays: Int) -> Note {
        let cal = Calendar.current
        let date = cal.date(byAdding: .day, value: offsetDays, to: now)!
        let note = Note(title: "n\(offsetDays)", body: "", tags: [], todos: [], createdAt: date, updatedAt: date)
        container.mainContext.insert(note)
        return note
    }

    // MARK: - Tests

    func test_emptyInput_returnsEmpty() {
        XCTAssertTrue(makeWeekGroups([], now: now).isEmpty)
    }

    func test_today_isThisWeek() {
        let groups = makeWeekGroups([makeNote(at: 0)], now: now)
        XCTAssertEqual(groups.first?.label, "This week")
    }

    func test_eightDaysAgo_isLastWeek() {
        // Definitely outside the current calendar week, within the previous one.
        let groups = makeWeekGroups([makeNote(at: -8)], now: now)
        XCTAssertEqual(groups.first?.label, "Last week")
    }

    func test_oneMonthAgoSameYear_usesMonthName() {
        // ~30 days back from mid-April lands in March.
        let groups = makeWeekGroups([makeNote(at: -30)], now: now)
        XCTAssertEqual(groups.first?.label, "March")
    }

    func test_olderYear_usesMonthAndYear() {
        // ~14 months ago — different calendar year.
        let groups = makeWeekGroups([makeNote(at: -420)], now: now)
        let label = groups.first?.label ?? ""
        XCTAssertTrue(label.contains("2025"), "Expected year suffix on cross-year bucket, got '\(label)'")
    }

    func test_sectionsPreserveInputOrder() {
        let today      = makeNote(at: 0)
        let lastWeek   = makeNote(at: -8)
        let lastMonth  = makeNote(at: -30)

        let groups = makeWeekGroups([today, lastWeek, lastMonth], now: now)
        XCTAssertEqual(groups.map(\.label), ["This week", "Last week", "March"])
    }

    func test_multipleNotesInSameBucket_collocate() {
        let a = makeNote(at: 0)
        let b = makeNote(at: -1)
        let c = makeNote(at: -2)

        let groups = makeWeekGroups([a, b, c], now: now)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.notes.count, 3)
    }
}
