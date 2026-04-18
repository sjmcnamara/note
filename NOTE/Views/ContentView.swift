import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: Space.xxl) {
            Text("NO.TE")
                .font(NoteFont.headline)
                .tracking(0.8)
                .foregroundStyle(Color.noteInk)

            Text("your notes,")
                .font(NoteFont.body)
                .foregroundStyle(Color.noteInkDim)
            + Text(" yours alone.")
                .font(NoteFont.italic(14))
                .foregroundStyle(Color.noteInkDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.noteBg)
    }
}

#Preview {
    ContentView()
}
