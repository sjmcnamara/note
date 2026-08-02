import SwiftUI
import SwiftData

// MARK: - EditorView

struct EditorView: View {
    @Bindable var note: Note
    var isNew: Bool = false
    @State private var saving = false
    @State private var saveTask: Task<Void, Never>?
    @State private var showPreview = false
    @State private var format = MarkdownEditorController()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    private var wordCount: Int {
        note.body.split { $0.isWhitespace }.count
    }

    private var isEmpty: Bool {
        note.title.isEmpty && note.body.isEmpty && note.todos.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            EditorTopBar(saving: saving, showPreview: $showPreview, onBack: { dismiss() }, onShare: {})

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    EditorTimestamp(date: note.createdAt)
                    TitleField(title: $note.title)
                    TagsRow(tags: $note.tags)

                    if showPreview {
                        MarkdownPreview(text: note.body)
                    } else {
                        BodyField(text: $note.body, controller: format) {
                            keyboardBar(chrome: true)
                        }
                        if !note.todos.isEmpty {
                            TodoSection(note: note, onEdit: markEdited, onAddTodo: addTodo)
                        }
                    }
                }
                .padding(.horizontal, 26)
                .padding(.top, 12)
                .padding(.bottom, 80)
            }
        }
        .background(Color.noteBg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar {
            // Shows when a SwiftUI field (title, tags, todos) has focus; the
            // body's UITextView carries the same bar as its input accessory.
            ToolbarItemGroup(placement: .keyboard) {
                keyboardBar(chrome: false)
            }
        }
        .onChange(of: note.title) { _, _ in markEdited() }
        .onChange(of: note.body) { _, _ in markEdited() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { persist() }
        }
        .onDisappear {
            saveTask?.cancel()
            let blanks = note.todos.filter { $0.text.isEmpty }
            note.todos.removeAll { $0.text.isEmpty }
            for item in blanks { modelContext.delete(item) }
            if isNew && isEmpty {
                modelContext.delete(note)
            }
            persist()
        }
    }

    private func persist() {
        do { try modelContext.save() } catch { print("EditorView save error: \(error)") }
    }

    private func markEdited() {
        note.updatedAt = Date()
        scheduleSave()
    }

    private func scheduleSave() {
        saveTask?.cancel()
        withAnimation(.spring(duration: 0.2)) { saving = true }
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                persist()
                withAnimation(.spring(duration: 0.4)) { saving = false }
            }
        }
    }

    private func keyboardBar(chrome: Bool) -> EditorKeyboardBar {
        EditorKeyboardBar(
            wordCount: wordCount,
            chrome: chrome,
            onBold: { format.toggleInline("**") },
            onItalic: { format.toggleInline("*") },
            onH1: { format.setHeading(1) },
            onH2: { format.setHeading(2) },
            onBullet: { format.toggleBullet() },
            onTodo: addTodo
        )
    }

    private func addTodo() {
        if note.todos.last?.text.isEmpty == true { return }
        let item = TodoItem(text: "")
        modelContext.insert(item)
        note.todos.append(item)
        markEdited()
    }
}

// MARK: - Top bar

private struct EditorTopBar: View {
    let saving: Bool
    @Binding var showPreview: Bool
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

                Button {
                    withAnimation(.easeInOut(duration: Motion.toggleSwap)) {
                        showPreview.toggle()
                    }
                } label: {
                    Image(systemName: showPreview ? "eye.fill" : "eye")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(showPreview ? Color.noteInk : Color.noteInkDim)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showPreview ? "Edit mode" : "Preview mode")

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
        if cal.isDateInToday(date) { return "Today" }
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
        ZStack(alignment: .topLeading) {
            TextField("", text: $title, axis: .vertical)
                .font(NoteFont.display)
                .foregroundStyle(focused || title.isEmpty ? Color.noteInk : Color.clear)
                .tint(Color.noteInk)
                .focused($focused)
                .lineLimit(1...3)
                .textContentType(.none)
                .submitLabel(.done)
                .onAppear { if title.isEmpty { focused = true } }
                .onChange(of: title) { _, new in
                    if new.contains("\n") || new.contains("\r") {
                        title = new
                            .replacingOccurrences(of: "\r\n", with: "")
                            .replacingOccurrences(of: "\n", with: "")
                            .replacingOccurrences(of: "\r", with: "")
                        focused = false
                    }
                }

            if !focused && !title.isEmpty {
                styledTitle.allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, Space.l)
    }

    private var styledTitle: some View {
        let words = title.components(separatedBy: " ")
        let last  = words.last ?? ""
        let rest  = words.dropLast().joined(separator: " ")

        let t: Text = rest.isEmpty
            ? Text(last).font(NoteFont.italic(28))
            : Text(rest + " ").font(NoteFont.display)
              + Text(last).font(NoteFont.italic(28))

        return t
            .foregroundStyle(Color.noteInk)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Tags row

private struct TagsRow: View {
    @Binding var tags: [String]
    @State private var addingTag = false
    @State private var draft = ""
    @FocusState private var tagFieldFocused: Bool
    @State private var expanded = false

    private static let collapseThreshold = 4

    private var visibleTags: [String] {
        guard !expanded && tags.count > Self.collapseThreshold else { return tags }
        return Array(tags.prefix(Self.collapseThreshold))
    }

    var body: some View {
        HStack(spacing: Space.base) {
            ForEach(visibleTags, id: \.self) { tag in
                HStack(spacing: 3) {
                    Text(tag)
                        .font(NoteFont.caption)
                        .foregroundStyle(Color.noteInkDim)
                    Button {
                        tags.removeAll { $0 == tag }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.noteInkMute)
                            .frame(width: 16, height: 16)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(tag) tag")
                }
            }

            if !expanded && tags.count > Self.collapseThreshold {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { expanded = true }
                } label: {
                    Text("…+\(tags.count - Self.collapseThreshold)")
                        .font(NoteFont.caption)
                        .foregroundStyle(Color.noteInkMute)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show \(tags.count - Self.collapseThreshold) more tags")
            }

            if addingTag {
                TextField("tag", text: $draft)
                    .font(NoteFont.caption)
                    .foregroundStyle(Color.noteInkDim)
                    .tint(Color.noteInk)
                    .focused($tagFieldFocused)
                    .frame(minWidth: 48)
                    .onSubmit { commitTag() }
                    .onAppear { tagFieldFocused = true }
            } else {
                Button {
                    draft = ""
                    addingTag = true
                } label: {
                    Text("+")
                        .font(NoteFont.caption)
                        .foregroundStyle(Color.noteInkMute)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, Space.sectionGap)
        .onChange(of: tagFieldFocused) { _, focused in
            if !focused { commitTag() }
        }
    }

    private func commitTag() {
        let trimmed = draft.trimmingCharacters(in: .whitespaces).lowercased()
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
        }
        draft = ""
        addingTag = false
    }
}

// MARK: - Body field

private struct BodyField: View {
    @Binding var text: String
    let controller: MarkdownEditorController
    let keyboardBar: () -> EditorKeyboardBar

    var body: some View {
        MarkdownTextView(text: $text, controller: controller, keyboardBar: keyboardBar)
            .padding(.bottom, Space.sectionGap)
    }
}

// MARK: - Markdown preview

private struct MarkdownPreview: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if text.isEmpty {
                Text("Nothing to preview.")
                    .font(NoteFont.body)
                    .foregroundStyle(Color.noteInkMute)
            } else {
                ForEach(Array(text.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                    lineView(for: line)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 360, alignment: .topLeading)
        .padding(.bottom, Space.sectionGap)
    }

    @ViewBuilder
    private func lineView(for line: String) -> some View {
        if line.hasPrefix("# ") {
            Text(inlineAttr(String(line.dropFirst(2))))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.noteInk)
                .padding(.top, 8)
                .padding(.bottom, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if line.hasPrefix("## ") {
            Text(inlineAttr(String(line.dropFirst(3))))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.noteInk)
                .padding(.top, 6)
                .padding(.bottom, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if line.hasPrefix("- ") {
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.noteInk)
                Text(inlineAttr(String(line.dropFirst(2))))
                    .font(.system(size: 15))
                    .foregroundStyle(Color.noteInk)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
        } else if line.isEmpty {
            Spacer().frame(height: 14)
        } else {
            Text(inlineAttr(line))
                .font(.system(size: 15))
                .foregroundStyle(Color.noteInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 1)
        }
    }

    // Parses only inline markdown (bold, italic) — block-level handled above per line.
    private func inlineAttr(_ string: String) -> AttributedString {
        var opts = AttributedString.MarkdownParsingOptions()
        opts.interpretedSyntax = .inlineOnly
        return (try? AttributedString(markdown: string, options: opts)) ?? AttributedString(string)
    }
}

// MARK: - Todo section

private struct TodoSection: View {
    @Bindable var note: Note
    let onEdit: () -> Void
    let onAddTodo: () -> Void
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("To do")
                .font(NoteFont.caption)
                .foregroundStyle(Color.noteInkMute)
                .padding(.bottom, Space.m)

            ForEach($note.todos) { $todo in
                TodoRow(
                    todo: $todo,
                    onEdit: onEdit,
                    onReturn: onAddTodo,
                    onDelete: {
                        if let idx = note.todos.firstIndex(where: { $0.id == todo.id }) {
                            modelContext.delete(note.todos[idx])
                            note.todos.remove(at: idx)
                            onEdit()
                        }
                    }
                )
            }
        }
        .padding(.top, Space.sectionGap)
    }
}

private struct TodoRow: View {
    @Binding var todo: TodoItem
    let onEdit: () -> Void
    let onReturn: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Space.m) {
            Button {
                todo.done.toggle()
                onEdit()
            } label: {
                Text(todo.done ? "▪" : "▢")
                    .font(NoteFont.body)
                    .foregroundStyle(todo.done ? Color.noteInkDim : Color.noteInkMute)
            }
            .buttonStyle(.plain)

            TextField("", text: $todo.text)
                .font(NoteFont.body)
                .foregroundStyle(todo.done ? Color.noteInkMute : Color.noteInk)
                .tint(Color.noteInk)
                .strikethrough(todo.done, color: Color.noteInkMute)
                .onChange(of: todo.text) { _, _ in onEdit() }
                .onSubmit { onReturn() }

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.noteInkMute)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Keyboard bar

/// Word count + formatting buttons. Rendered two ways: inside the SwiftUI
/// keyboard toolbar (chrome: false — SwiftUI supplies the bar background) and
/// as the body text view's input accessory (chrome: true — draws its own).
struct EditorKeyboardBar: View {
    let wordCount: Int
    let chrome: Bool
    let onBold: () -> Void
    let onItalic: () -> Void
    let onH1: () -> Void
    let onH2: () -> Void
    let onBullet: () -> Void
    let onTodo: () -> Void

    var body: some View {
        if chrome {
            row
                .padding(.horizontal, 18)
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .background(Color.noteBg)
                .overlay(alignment: .top) {
                    Color.noteRule.frame(height: 1)
                }
        } else {
            row
        }
    }

    private var row: some View {
        HStack(spacing: 0) {
            Text(wordCount == 1 ? "1 word" : "\(wordCount) words")
                .font(NoteFont.captionS)
                .foregroundStyle(Color.noteInkMute)

            Spacer()

            HStack(spacing: Space.s) {
                FormatBtn(label: "B", bold: true, action: onBold)
                FormatBtn(label: "I", italic: true, action: onItalic)
                FormatBtn(label: "H1", action: onH1)
                FormatBtn(label: "H2", action: onH2)
                FormatBtn(systemName: "list.bullet", action: onBullet)
                FormatBtn(systemName: "checkmark.square", action: onTodo)
            }
        }
    }
}

// MARK: - Format button (keyboard toolbar)

private struct FormatBtn: View {
    var label: String?
    var systemName: String?
    var bold: Bool = false
    var italic: Bool = false
    let action: () -> Void

    private var labelFont: Font {
        let base = Font.system(size: 14, weight: bold ? .bold : .regular)
        return italic ? base.italic() : base
    }

    var body: some View {
        Button(action: action) {
            if let sys = systemName {
                Image(systemName: sys)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.noteInkDim)
                    .frame(width: 28, height: 28)
            } else if let lbl = label {
                Text(lbl)
                    .font(labelFont)
                    .foregroundStyle(Color.noteInkDim)
                    .frame(width: 28, height: 28)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Note.self, configurations: config)
    let note = Note(
        title: "Thursday standup",
        body: "Short week. Focus on shipping the onboarding flow.",
        tags: ["work", "launch"],
        todos: [
            TodoItem(text: "Finalize launch copy w/ M"),
            TodoItem(text: "Rev pricing tiers — send to S"),
            TodoItem(text: "Cancel 2pm", done: true)
        ]
    )
    container.mainContext.insert(note)

    return NavigationStack {
        EditorView(note: note)
    }
    .modelContainer(container)
    .environmentObject(AppSettings.shared)
}
