import SwiftUI

// MARK: - EditorView

struct EditorView: View {
    @State private var note: Note
    @State private var saving = false
    @State private var saveTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss
    let onSave: (Note) -> Void

    init(note: Note, onSave: @escaping (Note) -> Void) {
        _note = State(initialValue: note)
        self.onSave = onSave
    }

    private var wordCount: Int {
        note.body.split { $0.isWhitespace }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            EditorTopBar(saving: saving, onBack: { dismiss() }, onShare: {})

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    EditorTimestamp(date: note.createdAt)
                    TitleField(title: $note.title)
                    TagsRow(tags: $note.tags)
                    BodyField(text: $note.body)
                    if !note.todos.isEmpty {
                        TodoSection(todos: $note.todos)
                    }
                }
                .padding(.horizontal, 26)
                .padding(.top, 12)
                .padding(.bottom, 80)
            }

            EditorToolBar(
                wordCount: wordCount,
                onHeading: { insert("## ") },
                onList:    { insert("- ") },
                onTodo:    { addTodo() },
                onImage:   {}
            )
        }
        .background(Color.noteBg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: note.title)             { _, _ in scheduleSave() }
        .onChange(of: note.body)              { _, _ in scheduleSave() }
        .onChange(of: note.todos.map(\.done)) { _, _ in scheduleSave() }
        .onChange(of: note.todos.map(\.text)) { _, _ in scheduleSave() }
        .onDisappear { onSave(note) }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        withAnimation(.spring(duration: 0.2)) { saving = true }
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                note.updatedAt = Date()
                onSave(note)
                withAnimation(.spring(duration: 0.4)) { saving = false }
            }
        }
    }

    private func insert(_ prefix: String) {
        note.body += note.body.isEmpty ? prefix : "\n" + prefix
    }

    private func addTodo() {
        note.todos.append(TodoItem(text: ""))
    }
}

// MARK: - Top bar

private struct EditorTopBar: View {
    let saving: Bool
    let onBack: () -> Void
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                HStack(spacing: Space.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                    Text("NO.TE")
                        .font(NoteFont.caption)
                }
                .foregroundStyle(Color.noteInkDim)
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: Space.xxl) {
                Circle()
                    .fill(saving ? Color.noteOk : Color.noteInkMute.opacity(0.4))
                    .frame(width: 6, height: 6)
                    .scaleEffect(saving ? 1.4 : 1.0)
                    .animation(.spring(duration: 0.3), value: saving)

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.noteInkDim)
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.noteInkDim)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 44)
    }
}

// MARK: - Timestamp

private struct EditorTimestamp: View {
    let date: Date

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()

    private var dayLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "EEEE"; return f.string(from: date)
    }

    var body: some View {
        Text("\(dayLabel) · \(Self.timeFmt.string(from: date))")
            .font(NoteFont.captionS)
            .foregroundStyle(Color.noteInkMute)
            .padding(.bottom, Space.m)
    }
}

// MARK: - Title field

private struct TitleField: View {
    @Binding var title: String
    @FocusState private var focused: Bool

    var body: some View {
        Group {
            if focused || title.isEmpty {
                TextField("", text: $title, axis: .vertical)
                    .font(.custom("Inter Tight", size: 26).weight(.medium))
                    .foregroundStyle(Color.noteInk)
                    .tint(Color.noteInk)
                    .focused($focused)
                    .lineLimit(1...6)
                    .textContentType(.none)
                    .onAppear { if title.isEmpty { focused = true } }
            } else {
                styledTitle
                    .onTapGesture { focused = true }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, Space.l)
    }

    // Last word rendered in Instrument Serif italic at 28pt; rest in Inter Tight 26/500
    private var styledTitle: some View {
        let words = title.components(separatedBy: " ")
        let last  = words.last ?? ""
        let rest  = words.dropLast().joined(separator: " ")

        let t: Text = rest.isEmpty
            ? Text(last).font(NoteFont.italic(28))
            : Text(rest + " ").font(.custom("Inter Tight", size: 26).weight(.medium))
              + Text(last).font(NoteFont.italic(28))

        return t
            .foregroundStyle(Color.noteInk)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Tags row

private struct TagsRow: View {
    @Binding var tags: [String]

    var body: some View {
        HStack(spacing: Space.base) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(NoteFont.caption)
                    .foregroundStyle(Color.noteInkDim)
            }
            Button(action: {}) {
                Text("+")
                    .font(NoteFont.caption)
                    .foregroundStyle(Color.noteInkMute)
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, Space.sectionGap)
    }
}

// MARK: - Body field

private struct BodyField: View {
    @Binding var text: String

    var body: some View {
        TextEditor(text: $text)
            .font(.custom("Inter Tight", size: 15))
            .foregroundStyle(Color.noteInk)
            .tint(Color.noteInk)
            .scrollContentBackground(.hidden)
            .lineSpacing(9) // ~1.6 line height on 15pt font
            .frame(minHeight: 120)
            .textContentType(.none)
            .padding(.bottom, Space.sectionGap)
    }
}

// MARK: - Todo section

private struct TodoSection: View {
    @Binding var todos: [TodoItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("To do")
                .font(NoteFont.caption)
                .foregroundStyle(Color.noteInkMute)
                .padding(.bottom, Space.m)

            ForEach($todos) { $todo in
                TodoRow(todo: $todo)
            }
        }
        .padding(.top, Space.sectionGap)
    }
}

private struct TodoRow: View {
    @Binding var todo: TodoItem

    var body: some View {
        HStack(alignment: .center, spacing: Space.m) {
            Button { todo.done.toggle() } label: {
                Text(todo.done ? "▪" : "▢")
                    .font(.custom("Inter Tight", size: 14))
                    .foregroundStyle(todo.done ? Color.noteInkDim : Color.noteInkMute)
            }
            .buttonStyle(.plain)

            TextField("", text: $todo.text)
                .font(.custom("Inter Tight", size: 14))
                .foregroundStyle(todo.done ? Color.noteInkMute : Color.noteInk)
                .tint(Color.noteInk)
                .strikethrough(todo.done, color: Color.noteInkMute)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Bottom toolbar

private struct EditorToolBar: View {
    let wordCount: Int
    let onHeading: () -> Void
    let onList:    () -> Void
    let onTodo:    () -> Void
    let onImage:   () -> Void

    var body: some View {
        HStack {
            Text("\(wordCount) words")
                .font(NoteFont.captionS)
                .foregroundStyle(Color.noteInkMute)

            Spacer()

            HStack(spacing: Space.xs) {
                ToolBtn(systemName: "textformat",    action: onHeading)
                ToolBtn(systemName: "list.bullet",   action: onList)
                ToolBtn(systemName: "checkmark.square", action: onTodo)
                ToolBtn(systemName: "photo",         action: onImage)
            }
            .padding(.horizontal, Space.m)
            .padding(.vertical, Space.s)
            .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.pill))
        }
        .padding(.horizontal, Space.gutterH)
        .padding(.bottom, 22)
        .frame(height: 44)
        .background(Color.noteBg)
    }
}

private struct ToolBtn: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.noteInkDim)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EditorView(note: Note(

            title: "Thursday standup",
            body: "Short week. Focus on shipping the onboarding flow — S is unblocked on pricing once copy lands.",
            tags: ["work", "launch"],
            todos: [
                TodoItem(text: "Finalize launch copy w/ M"),
                TodoItem(text: "Rev pricing tiers — send to S"),
                TodoItem(text: "Cancel 2pm", done: true),
                TodoItem(text: "Ship onboarding by Fri"),
            ],
            createdAt: Date(),
            updatedAt: Date()
        ), onSave: { _ in })
    }
}
