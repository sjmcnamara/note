import SwiftUI

struct EditorView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xxl) {
            Text(note.title.isEmpty ? "New note" : note.title)
                .font(NoteFont.displayL)
                .foregroundStyle(Color.noteInk)

            Text("Editor coming soon.")
                .font(NoteFont.body)
                .foregroundStyle(Color.noteInkDim)

            Spacer()
        }
        .padding(.horizontal, Space.gutterH)
        .padding(.top, Space.sectionGap)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.noteBg.ignoresSafeArea())
        .navigationTitle("NO.TE")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EditorView(note: Note(
            title: "Thursday standup",
            body: "Finalize launch copy.",
            tags: ["work"],
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
