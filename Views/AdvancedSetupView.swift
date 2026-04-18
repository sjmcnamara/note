import SwiftUI

// Placeholder — full implementation in "feat: advanced setup" PR.
struct AdvancedSetupView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.noteInkDim)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Space.gutterH)

            Spacer()

            VStack(alignment: .leading, spacing: Space.l) {
                Text("Advanced setup")
                    .font(NoteFont.displayL)
                    .foregroundStyle(Color.noteInk)

                Text("Coming soon — keys, relays, import.")
                    .font(NoteFont.body)
                    .foregroundStyle(Color.noteInkDim)
            }
            .padding(.horizontal, Space.gutterH)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.noteBg.ignoresSafeArea())
    }
}

#Preview {
    AdvancedSetupView()
}
