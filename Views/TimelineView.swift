import SwiftUI
import SwiftData

// MARK: - TimelineView

struct TimelineView: View {
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]
    @Environment(\.modelContext) private var modelContext
    @State private var showSearch = false
    @State private var composeNote: Note?
    @State private var editingNote: Note?
    @State private var pinnedTag: String?

    private var tags: [String] {
        var seen = Set<String>()
        return notes.flatMap(\.tags).filter { seen.insert($0).inserted }
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

                    if notes.isEmpty {
                        EmptyTimelineView(onStartNote: createNote)
                    } else {
                        TagStrip(tags: tags) { pinnedTag = $0 }

                        List {
                            ForEach(makeGroups(notes)) { group in
                                Section {
                                    ForEach(group.notes) { note in
                                        noteRow(note)
                                    }
                                } header: {
                                    dayHeader(group.label)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .environment(\.defaultMinListHeaderHeight, 0)
                        .contentMargins(.bottom, 96, for: .scrollContent)
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
            .navigationDestination(item: $editingNote) { note in
                EditorView(note: note)
            }
            .navigationDestination(item: $pinnedTag) { tag in
                TagFilterView(tag: tag)
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

    private func dayHeader(_ label: String) -> some View {
        HStack {
            Text(label)
                .font(NoteFont.captionS)
                .foregroundStyle(Color.noteInkMute)
                .textCase(nil)
            Spacer()
        }
        .padding(.horizontal, Space.gutterH)
        .padding(.top, Space.sectionGap)
        .padding(.bottom, Space.m)
        .background(Color.noteBg)
        .listRowInsets(EdgeInsets())
    }

    @ViewBuilder
    private func noteRow(_ note: Note) -> some View {
        Button { editingNote = note } label: {
            NoteRow(note: note)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.noteBg)
        .listRowInsets(EdgeInsets())
        .listRowSeparatorTint(Color.noteRule)
        .alignmentGuide(.listRowSeparatorLeading) { _ in Space.gutterH }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation { modelContext.delete(note) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
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
    let onTap: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(tags, id: \.self) { tag in
                    TagChip(label: tag) { onTap(tag) }
                }
            }
            .padding(.horizontal, Space.gutterH)
            .padding(.vertical, Space.m)
        }
    }
}

private struct TagChip: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(NoteFont.bodyS)
                .foregroundStyle(Color.noteInkMute)
                .padding(.vertical, 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open \(label) tag")
    }
}

// MARK: - Note row

private struct NoteRow: View {
    let note: Note

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
                        .font(NoteFont.body)
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
