import SwiftUI

// Stub — full implementation in Screen 7 PR.
struct KeyImportView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: Space.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Back")
                            .font(NoteFont.caption)
                    }
                    .foregroundStyle(Color.noteInkDim)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Import key")
                    .font(NoteFont.titleS)
                    .foregroundStyle(Color.noteInk)
            }
            .padding(.horizontal, Space.gutterH)
            .padding(.top, 44)
            .padding(.bottom, Space.s)

            Spacer()

            VStack(alignment: .leading, spacing: Space.l) {
                Text("Key import")
                    .font(NoteFont.displayL)
                    .foregroundStyle(Color.noteInk)

                Text("Paste field, QR scan, and bech32 validation land in Screen 7.")
                    .font(NoteFont.body)
                    .foregroundStyle(Color.noteInkDim)
            }
            .padding(.horizontal, Space.gutterH)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.noteBg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        KeyImportView()
    }
}
