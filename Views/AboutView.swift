import SwiftUI

// MARK: - AboutView

struct AboutView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.sectionGap) {
                AboutNavBar()

                VStack(alignment: .leading, spacing: Space.l) {
                    Text("NO.TE")
                        .font(NoteFont.displayL)
                        .tracking(0.8)
                        .foregroundStyle(Color.noteInk)

                    Text("A quiet place for your thoughts.")
                        .font(NoteFont.bodyS)
                        .foregroundStyle(Color.noteInkDim)
                }

                VStack(spacing: 0) {
                    infoRow(label: "Version", value: version)
                    Rectangle().fill(Color.noteRule).frame(height: 1)
                    infoRow(label: "Build",   value: build)
                }

                Text("Built on Nostr. An open protocol.")
                    .font(NoteFont.captionS)
                    .foregroundStyle(Color.noteInkMute)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, Space.m)
            }
            .padding(.horizontal, Space.gutterH)
            .padding(.bottom, Space.sectionGap * 2)
        }
        .background(Color.noteBg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(NoteFont.body)
                .foregroundStyle(Color.noteInk)
            Spacer()
            Text(value)
                .font(NoteFont.captionS)
                .foregroundStyle(Color.noteInkMute)
                .monospacedDigit()
        }
        .padding(.vertical, Space.l)
    }
}

// MARK: - Nav bar

private struct AboutNavBar: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: Space.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                    Text("Settings")
                        .font(NoteFont.caption)
                }
                .foregroundStyle(Color.noteInkDim)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("About")
                .font(NoteFont.titleS)
                .foregroundStyle(Color.noteInk)
        }
        .padding(.top, 44)
        .padding(.bottom, Space.s)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AboutView()
    }
}
