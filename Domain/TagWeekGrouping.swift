import Foundation

// Pure grouping helper used by `TagFilterView`. Extracted out of the view so
// it can be unit-tested with a fixed `now` reference.

struct WeekGroup: Identifiable {
    let id = UUID()
    let label: String
    let notes: [Note]
}

/// Buckets notes into "This week", "Last week", or month-name sections.
///
/// - "This week" / "Last week" use `Calendar.dateInterval(of: .weekOfYear, ...)`.
/// - Older notes within the same year use the month name only ("March").
/// - Older notes in a different year include the year ("March 2025").
///
/// Sections appear in the order their first note is encountered, which means
/// when `notes` is already sorted newest-first the sections naturally render
/// newest-first too.
func makeWeekGroups(_ notes: [Note], now: Date = Date()) -> [WeekGroup] {
    let cal = Calendar.current
    let weekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? now
    let lastWeekStart = cal.date(byAdding: .day, value: -7, to: weekStart) ?? weekStart

    let monthFmt = DateFormatter(); monthFmt.dateFormat = "MMMM"
    let monthYearFmt = DateFormatter(); monthYearFmt.dateFormat = "MMMM yyyy"
    let nowYear = cal.component(.year, from: now)

    func bucketLabel(for date: Date) -> String {
        if date >= weekStart { return "This week" }
        if date >= lastWeekStart { return "Last week" }
        let dateYear = cal.component(.year, from: date)
        return dateYear == nowYear ? monthFmt.string(from: date) : monthYearFmt.string(from: date)
    }

    var order: [String] = []
    var byLabel: [String: [Note]] = [:]
    for note in notes {
        let label = bucketLabel(for: note.createdAt)
        if byLabel[label] == nil { order.append(label) }
        byLabel[label, default: []].append(note)
    }
    return order.map { WeekGroup(label: $0, notes: byLabel[$0] ?? []) }
}
