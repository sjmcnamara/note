import SwiftUI
import SwiftData

// MARK: - Grouping

private struct DayGroup: Identifiable {
    let id = UUID()
    let label: String
    let notes: [Note]
}

private func makeGroups(_ notes: [Note]) -> [DayGroup] {
    let cal = Calendar.current
    let today     = cal.startOfDay(for: Date())
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

// MARK: - TimelineView

struct TimelineView: View {
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]
    @Environment(\.modelContext) private var modelContext
    @State private var activeTag: String? = nil
    @State private var showSearch = false
    @State private var composeNote: Note?

    private let defaultTags = ["work", "daily", "ideas", "reading", "dreams"]

    private var tags: [String] {
        var seen = Set(defaultTags)
        let extra = notes.flatMap(\.tags).filter { seen.insert($0).inserted }
        return defaultTags + extra
    }

    private var filtered: [Note] {
        guard let t = activeTag else { return notes }
        return notes.filter { $0.tags.contains(t) }
    }

    private func createNote() {
        let note = Note(title: "", body: "", tags: [])
        modelContext.insert(note)
        composeNote = note
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    TimelineHeader(showSearch: $showSearch)
                    TagStrip(tags: tags, activeTag: $activeTag)

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(makeGroups(filtered)) { group in
                                DaySection(group: group)
                            }
                        }
                        .padding(.bottom, 96)
                    }
                }

                TimelineComposeBar(onCreate: createNote)
                    .padding(.horizontal, Space.gutterH)
                    .padding(.bottom, 24)
            }
            .background(Color.noteBg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $composeNote) { note in
                EditorView(note: note, isNew: true)
            }
            .overlay {
                if showSearch {
                    SearchView(notes: notes, onDismiss: {
                        withAnimation(.easeInOut(duration: 0.15)) { showSearch = false }
                    })
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: showSearch)
        }
    }
}

// MARK: - Header

private struct TimelineHeader: View {
    @Binding var showSearch: Bool

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"
        return f
    }()

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.dateFmt.string(from: Date()))
                    .font(NoteFont.captionS)
                    .foregroundStyle(Color.noteInkMute)

                Text("NO.TE")
                    .font(NoteFont.headline)
                    .tracking(0.8)
                    .foregroundStyle(Color.noteInk)
            }

            Spacer()

            HStack(spacing: Space.m) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { showSearch = true }
                } label: {
                    IconTile(systemName: "magnifyingglass")
                }
                .buttonStyle(.plain)

                NavigationLink { SettingsView() } label: {
                    IconTile(systemName: "gearshape")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Space.gutterH)
        .padding(.top, 56)
        .padding(.bottom, Space.l)
    }
}

private struct IconTile: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(Color.noteInk)
            .frame(width: 32, height: 32)
            .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.l))
    }
}

// MARK: - Tag strip

private struct TagStrip: View {
    let tags: [String]
    @Binding var activeTag: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                TagChip(label: "all", active: activeTag == nil) {
                    activeTag = nil
                }
                ForEach(tags, id: \.self) { tag in
                    TagChip(label: tag, active: activeTag == tag) {
                        activeTag = (activeTag == tag) ? nil : tag
                    }
                }
            }
            .padding(.horizontal, Space.gutterH)
            .padding(.vertical, Space.m)
        }
    }
}

private struct TagChip: View {
    let label: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(label)
                    .font(NoteFont.bodyS)
                    .foregroundStyle(active ? Color.noteInk : Color.noteInkMute)

                Rectangle()
                    .fill(active ? Color.noteInk : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("filter: \(label)")
    }
}

// MARK: - Day section

private struct DaySection: View {
    let group: DayGroup

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(group.label)
                    .font(NoteFont.captionS)
                    .foregroundStyle(Color.noteInkMute)
                Spacer()
            }
            .padding(.horizontal, Space.gutterH)
            .padding(.top, Space.sectionGap)
            .padding(.bottom, Space.m)

            ForEach(Array(group.notes.enumerated()), id: \.element.id) { i, note in
                VStack(spacing: 0) {
                    if i > 0 {
                        Rectangle()
                            .fill(Color.noteRule)
                            .frame(height: 1)
                            .padding(.leading, Space.gutterH)
                    }
                    NavigationLink { EditorView(note: note) } label: {
                        NoteRow(note: note)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Note row

private struct NoteRow: View {
    let note: Note
    @AppStorage("textSizeStep") private var textSizeStep = 0

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: Space.xxl) {
            Text(Self.timeFmt.string(from: note.createdAt))
                .font(NoteFont.captionS)
                .foregroundStyle(Color.noteInkMute)
                .frame(width: 36, alignment: .leading)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: Space.xs) {
                if !note.title.isEmpty {
                    Text(note.title)
                        .font(NoteFont.titleS)
                        .foregroundStyle(Color.noteInk)
                        .lineLimit(2)
                }

                if !note.body.isEmpty {
                    Text(note.body)
                        .font(.custom("Inter Tight", size: 14 + CGFloat(textSizeStep * 3)))
                        .foregroundStyle(Color.noteInkDim)
                        .lineLimit(2)
                }

                if !note.tags.isEmpty {
                    HStack(spacing: Space.m) {
                        ForEach(note.tags, id: \.self) { tag in
                            Text(tag)
                                .font(NoteFont.captionS)
                                .foregroundStyle(Color.noteInkMute)
                        }
                    }
                    .padding(.top, Space.xxs)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Space.gutterH)
        .padding(.vertical, Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            [Self.timeFmt.string(from: note.createdAt), note.title, note.body]
                .filter { !$0.isEmpty }
                .joined(separator: ". ")
        )
    }
}

// MARK: - Compose bar

private struct TimelineComposeBar: View {
    let onCreate: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text("Write something…")
                .font(NoteFont.body)
                .foregroundStyle(Color.noteInkMute)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, Space.sectionGap)

            Image(systemName: "mic")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.noteInkDim)
                .frame(width: 36, height: 36)

            Button(action: onCreate) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.noteBg)
                    .frame(width: 36, height: 36)
                    .background(Color.noteInk, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, Space.m)
        }
        .frame(height: 54)
        .background(Color.noteBg, in: RoundedRectangle(cornerRadius: Radius.xxl))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xxl)
                .strokeBorder(Color.noteRule, lineWidth: 1)
        )
        .composeShadow()
    }
}

// MARK: - Preview

#Preview {
    TimelineView()
        .modelContainer(for: Note.self, inMemory: true)
}
