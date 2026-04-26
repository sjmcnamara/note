import Foundation

// Pure grouping helper used by `TimelineView`. Extracted out of the view so
// it can be unit-tested with a fixed `now` reference.

struct DayGroup: Identifiable {
    let id = UUID()
    let label: String
    let notes: [Note]
}

/// Buckets notes into day-grouped sections.
/// - Today / Yesterday for the latest two days.
/// - Weekday name (e.g. "Tuesday") for anything within the last 6 days before yesterday.
/// - "d MMMM" (e.g. "3 March") for older dates.
func makeGroups(_ notes: [Note], now: Date = Date()) -> [DayGroup] {
    let cal = Calendar.current
    let today     = cal.startOfDay(for: now)
    let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
    let weekStart = cal.date(byAdding: .day, value: -6, to: today)!

    let weekdayFmt = DateFormatter(); weekdayFmt.dateFormat = "EEEE"
    let dateFmt    = DateFormatter(); dateFmt.dateFormat   = "d MMMM"

    let byDay = Dictionary(grouping: notes) { cal.startOfDay(for: $0.createdAt) }

    return byDay.keys.sorted(by: >).map { day in
        let label: String
        if cal.isDate(day, inSameDayAs: today) {
            label = "Today"
        } else if cal.isDate(day, inSameDayAs: yesterday) {
            label = "Yesterday"
        } else if day >= weekStart {
            label = weekdayFmt.string(from: day)
        } else {
            label = dateFmt.string(from: day)
        }
        return DayGroup(label: label, notes: byDay[day]!.sorted { $0.createdAt > $1.createdAt })
    }
}
