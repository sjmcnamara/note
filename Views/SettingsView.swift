import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: Space.xxl) {
            Text("Settings")
                .font(NoteFont.headline)
                .foregroundStyle(Color.noteInk)

            Text("Settings coming soon.")
                .font(NoteFont.body)
                .foregroundStyle(Color.noteInkDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.noteBg.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
