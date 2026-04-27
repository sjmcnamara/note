import SwiftUI
import SwiftData

// MARK: - TagFilterView

struct TagFilterView: View {
    let tag: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    // [String] is stored as Transformable in SwiftData — #Predicate cannot filter it at the
    // SQL level. Fetch all notes and filter in memory instead.
    @Query(sort: \Note.createdAt, order: .reverse) private var allNotes: [Note]

    @State private var showRename = false
    @State private var renameDraft = ""
    @State private var showDeleteConfirm = false
    @State private var nestedTag: String?
    @State private var editingNote: Note?

    init(tag: String) {
        self.tag = tag
    }

    private var notes: [Note] {
        allNotes.filter { $0.tags.contains(tag) }
    }

    var body: some View {
        VStack(spacing: 0) {
            NavBar(
                title: tag,
                onBack: { dismiss() },
                onRename: { renameDraft = tag; showRename = true },
                onDelete: { showDeleteConfirm = true }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Header(
                        tag: tag,
                        count: notes.count,
                        sinceDate: notes.last?.createdAt,
                        onRename: { renameDraft = tag; showRename = true }
                    )
                    .padding(.horizontal, Space.gutterH)
                    .padding(.top, Space.l)
                    .padding(.bottom, Space.sectionGap)

                    if !relatedTags.isEmpty {
                        RelatedTagStrip(tags: relatedTags) { related in
                            nestedTag = related
                        }
                        .padding(.bottom, Space.sectionGap)
                    }

                    LazyVStack(spacing: 0) {
                        ForEach(makeWeekGroups(notes)) { group in
                            WeekSection(group: group, onTap: { editingNote = $0 }, onDelete: deleteNote)
                        }
                    }
                    .padding(.bottom, Space.sectionGap)
                }
            }
        }
        .background(Color.noteBg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $nestedTag) { TagFilterView(tag: $0) }
        .navigationDestination(item: $editingNote) { EditorView(note: $0) }
        .alert("Rename tag", isPresented: $showRename) {
            TextField("Tag name", text: $renameDraft)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Rename") { rename(to: renameDraft) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All notes tagged \u{201C}\(tag)\u{201D} will be updated.")
        }
        .confirmationDialog("Delete this tag?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete tag", role: .destructive) { deleteTag() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Notes will keep their content but lose the \u{201C}\(tag)\u{201D} tag.")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(tag) tag, \(notes.count) notes. Scroll for related tags and matching notes.")
    }

    // MARK: - Derived

    private var relatedTags: [String] {
        var counts: [String: Int] = [:]
        for note in notes {
            for other in note.tags where other != tag {
                counts[other, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value || ($0.value == $1.value && $0.key < $1.key) }
            .prefix(6)
            .map(\.key)
    }

    // MARK: - Mutations

    private func rename(to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty, trimmed != tag else { return }
        for note in notes {
            note.tags = note.tags.map { $0 == tag ? trimmed : $0 }
        }
        try? modelContext.save()
        dismiss()
    }

    private func deleteTag() {
        for note in notes {
            note.tags.removeAll { $0 == tag }
        }
        try? modelContext.save()
        dismiss()
    }

    private func deleteNote(_ note: Note) {
        modelContext.delete(note)
        try? modelContext.save()
    }
}

// MARK: - Nav bar

private struct NavBar: View {
    let title: String
    let onBack: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: Space.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                    Text("All")
                        .font(NoteFont.caption)
                }
                .foregroundStyle(Color.noteInkDim)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(NoteFont.titleS)
                .foregroundStyle(Color.noteInk)
                .lineLimit(1)

            Spacer()

            Menu {
                Button("Rename") { onRename() }
                Button("Delete tag", role: .destructive) { onDelete() }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.noteInkDim)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, Space.gutterH)
        .padding(.top, 44)
        .padding(.bottom, Space.s)
    }
}

// MARK: - Header

private struct Header: View {
    let tag: String
    let count: Int
    let sinceDate: Date?
    let onRename: () -> Void

    private static let sinceFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d MMMM"; return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text(tag)
                .font(NoteFont.italic(32))
                .foregroundStyle(Color.noteInk)
                .lineLimit(2)

            HStack(spacing: 0) {
                Text(metaPrefix)
                    .font(Font.custom("Inter Tight", size: 12.5, relativeTo: .caption))
                    .foregroundStyle(Color.noteInkDim)
                Button(action: onRename) {
                    Text("rename")
                        .font(Font.custom("Inter Tight", size: 12.5, relativeTo: .caption))
                        .foregroundStyle(Color.noteInkDim)
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var metaPrefix: String {
        let n = count == 1 ? "1 note" : "\(count) notes"
        guard let sinceDate else { return "\(n) · " }
        return "\(n) · since \(Self.sinceFmt.string(from: sinceDate)) · "
    }
}

// MARK: - Related tags

private struct RelatedTagStrip: View {
    let tags: [String]
    let onTap: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: Space.m) {
                Text("often with:")
                    .font(Font.custom("Inter Tight", size: 12.5, relativeTo: .caption))
                    .foregroundStyle(Color.noteInkMute)

                ForEach(tags, id: \.self) { related in
                    Button { onTap(related) } label: {
                        Text(related)
                            .font(Font.custom("Inter Tight", size: 12.5, relativeTo: .caption))
                            .foregroundStyle(Color.noteInkDim)
                            .padding(.horizontal, Space.base)
                            .padding(.vertical, Space.xs)
                            .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.pill))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Space.gutterH)
        }
    }
}

// MARK: - Week section + row

private struct WeekSection: View {
    let group: WeekGroup
    let onTap: (Note) -> Void
    let onDelete: (Note) -> Void

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
                    Button { onTap(note) } label: {
                        TagNoteRow(note: note)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation { onDelete(note) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}

private struct TagNoteRow: View {
    let note: Note

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d MMM"; return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: Space.xxl) {
            Text(Self.timeFmt.string(from: note.createdAt))
                .font(NoteFont.captionS)
                .foregroundStyle(Color.noteInkMute)
                .frame(width: 48, alignment: .leading)
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Space.gutterH)
        .padding(.vertical, Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TagFilterView(tag: "work")
    }
    .modelContainer(for: Note.self, inMemory: true)
}
