import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Space.xxl) {
            Text("Search")
                .font(NoteFont.headline)
                .foregroundStyle(Color.noteInk)

            Text("Search coming soon.")
                .font(NoteFont.body)
                .foregroundStyle(Color.noteInkDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.noteBg.ignoresSafeArea())
    }
}

#Preview {
    SearchView()
}
