import SwiftUI

// MARK: - SearchView

struct SearchView: View {
    let notes: [Note]
    let onDismiss: () -> Void

    @State private var query = ""

    private var matches: [Note] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return notes.filter {
            $0.title.lowercased().contains(q) ||
            $0.body.lowercased().contains(q) ||
            $0.tags.contains { $0.lowercased().contains(q) }
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            SearchCard(query: $query, matches: matches, onDismiss: onDismiss)
                .padding(.horizontal, 14)
                .padding(.top, 88)
        }
    }
}

// MARK: - Card

private struct SearchCard: View {
    @Binding var query: String
    let matches: [Note]
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            QueryBar(query: $query)

            if !query.isEmpty {
                Rectangle()
                    .fill(Color.noteRule)
                    .frame(height: 1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if !matches.isEmpty {
                            NotesSection(notes: matches, onTap: { _ in onDismiss() })
                        }
                        ActionsSection(query: query, onAction: onDismiss)
                    }
                }
                .frame(maxHeight: 440)
            }
        }
        .background(Color.noteBg, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.18), radius: 25, y: 10)
    }
}

// MARK: - Query bar

private struct QueryBar: View {
    @Binding var query: String
    @FocusState private var focused: Bool
    @State private var caretOn = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Space.m) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.noteInkDim)

            ZStack(alignment: .leading) {
                TextField("", text: $query)
                    .font(Font.custom("Inter Tight", size: 15, relativeTo: .subheadline))
                    .foregroundStyle(Color.noteInk)
                    .tint(.clear)
                    .focused($focused)
                    .accessibilityLabel("Search notes")

                // Invisible text mirror pushes caret to sit 2pt after last character
                HStack(spacing: 0) {
                    Text(query)
                        .font(Font.custom("Inter Tight", size: 15, relativeTo: .subheadline))
                        .lineLimit(1)
                        .foregroundStyle(.clear)
                        .fixedSize(horizontal: true, vertical: false)

                    Rectangle()
                        .fill(caretOn ? Color.noteInk : Color.clear)
                        .frame(width: 2, height: 16)
                        .padding(.leading, 2)
                }
                .allowsHitTesting(false)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .onAppear { focused = true }
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                caretOn.toggle()
            }
        }
    }
}

// MARK: - Notes section

private struct NotesSection: View {
    let notes: [Note]
    let onTap: (Note) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Notes")
                .font(NoteFont.captionS)
                .foregroundStyle(Color.noteInkMute)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, Space.m)

            ForEach(Array(notes.prefix(4).enumerated()), id: \.element.id) { i, note in
                VStack(spacing: 0) {
                    if i > 0 {
                        Rectangle()
                            .fill(Color.noteRule)
                            .frame(height: 1)
                            .padding(.leading, 16)
                    }
                    SearchNoteRow(note: note)
                        .contentShape(Rectangle())
                        .onTapGesture { onTap(note) }
                }
            }
        }
    }
}

private struct SearchNoteRow: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(note.title.isEmpty ? note.body : note.title)
                    .font(NoteFont.titleS)
                    .foregroundStyle(Color.noteInk)
                    .lineLimit(1)
                Spacer()
                Text(relativeDate(note.createdAt))
                    .font(NoteFont.captionS)
                    .foregroundStyle(Color.noteInkMute)
            }

            if !note.title.isEmpty, !note.body.isEmpty {
                Text(note.body)
                    .font(NoteFont.captionS)
                    .foregroundStyle(Color.noteInkDim)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, Space.l)
    }

    private func relativeDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: date)
        }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "d MMM"; return f.string(from: date)
    }
}

// MARK: - Actions section

private struct ActionsSection: View {
    let query: String
    let onAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.noteRule)
                .frame(height: 1)

            Text("Actions")
                .font(NoteFont.captionS)
                .foregroundStyle(Color.noteInkMute)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, Space.m)

            SearchActionRow(systemName: "plus",
                            label: "New note with this tag",
                            onTap: onAction)
            SearchActionRow(systemName: "chevron.right",
                            label: "See all in \u{201C}\(query)\u{201D}",
                            onTap: onAction)
        }
    }
}

private struct SearchActionRow: View {
    let systemName: String
    let label: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Space.l) {
                Image(systemName: systemName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.noteInkDim)
                    .frame(width: 22, height: 22)
                    .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.s))

                Text(label)
                    .font(NoteFont.bodyS)
                    .foregroundStyle(Color.noteInk)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, Space.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        SearchView(notes: [], onDismiss: {})
    }
}
