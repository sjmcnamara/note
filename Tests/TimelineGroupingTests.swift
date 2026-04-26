import XCTest
import SwiftData
@testable import NOTE

@MainActor
final class TimelineGroupingTests: XCTestCase {

    // Anchor "now" to a stable Wednesday: 2026-04-15 12:00 UTC.
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

    private func makeNote(at offsetDays: Int, hour: Int = 9) -> Note {
        let cal = Calendar.current
        let date = cal.date(byAdding: .day, value: offsetDays, to: now)!.addingTimeInterval(TimeInterval(hour * 3600 - 12 * 3600))
        let note = Note(title: "n\(offsetDays).\(hour)", body: "", tags: [], todos: [], createdAt: date, updatedAt: date)
        container.mainContext.insert(note)
        return note
    }

    // MARK: - Tests

    func test_emptyInput_returnsEmpty() {
        XCTAssertTrue(makeGroups([], now: now).isEmpty)
    }

    func test_todayLabel() {
        let n = makeNote(at: 0)
        let groups = makeGroups([n], now: now)
        XCTAssertEqual(groups.first?.label, "Today")
    }

    func test_yesterdayLabel() {
        let n = makeNote(at: -1)
        let groups = makeGroups([n], now: now)
        XCTAssertEqual(groups.first?.label, "Yesterday")
    }

    func test_weekdayLabel_forNotesWithinPastWeek() {
        // 3 days ago — should be a weekday name (not Today/Yesterday).
        let n = makeNote(at: -3)
        let label = makeGroups([n], now: now).first?.label ?? ""
        let weekdayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        XCTAssertTrue(weekdayNames.contains(label), "Got '\(label)' which is not a weekday name")
    }

    func test_oldDateUsesDayMonthFormat() {
        // 30 days ago — should be "d MMMM" format.
        let n = makeNote(at: -30)
        let label = makeGroups([n], now: now).first?.label ?? ""
        XCTAssertTrue(label.contains("March") || label.contains("February"),
                      "Expected a month name in label, got '\(label)'")
    }

    func test_groupsAreOrderedNewestFirst() {
        let today    = makeNote(at: 0)
        let yest     = makeNote(at: -1)
        let oldDay   = makeNote(at: -10)

        let groups = makeGroups([oldDay, yest, today], now: now)
        XCTAssertEqual(groups.count, 3)
        XCTAssertEqual(groups[0].label, "Today")
        XCTAssertEqual(groups[1].label, "Yesterday")
        // Oldest last; we don't assert exact label of the 30-days-ago bucket.
    }

    func test_multipleNotesSameDayAreCollocated() {
        let a = makeNote(at: 0, hour: 9)
        let b = makeNote(at: 0, hour: 14)
        let c = makeNote(at: 0, hour: 18)

        let groups = makeGroups([a, b, c], now: now)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].notes.count, 3)
        // Sorted descending by createdAt within a day.
        XCTAssertEqual(groups[0].notes.map(\.title), ["n0.18", "n0.14", "n0.9"])
    }
}
