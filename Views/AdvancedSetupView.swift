import SwiftUI

// MARK: - AdvancedSetupView

struct AdvancedSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showImport = false
    @State private var toastMessage: String?
    var onComplete: (() -> Void)?

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                NavBar { dismiss() }

                ScrollView {
                    VStack(alignment: .leading, spacing: Space.sectionGap) {
                        Hero()
                        SubText()
                        VStack(spacing: Space.base) {
                            OptionRow(
                                title: "Generate new keys",
                                caption: "A fresh npub / nsec for this device",
                                badge: "recommended",
                                recommended: true,
                                action: generate
                            )
                            OptionRow(
                                title: "Import existing nsec",
                                caption: "Paste or scan a secret key you already own",
                                action: { showImport = true }
                            )
                            OptionRow(
                                title: "Restore from backup",
                                caption: "Connect a relay and decrypt with your nsec",
                                action: restore
                            )
                        }
                        Footer()
                    }
                    .padding(.horizontal, Space.gutterH)
                    .padding(.top, Space.l)
                    .padding(.bottom, Space.sectionGap * 2)
                }
            }

            if let toastMessage {
                Toast(message: toastMessage)
                    .padding(.horizontal, Space.gutterH)
                    .padding(.top, Space.m)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color.noteBg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showImport) {
            KeyImportView()
        }
    }

    private func generate() {
        _ = MockIdentity.generate()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        if let onComplete {
            onComplete()
        } else {
            dismiss()
        }
    }

    private func restore() {
        showToast("Restore flow lands with real Nostr.")
    }

    private func showToast(_ message: String) {
        withAnimation(.spring(duration: 0.25)) { toastMessage = message }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeOut(duration: 0.2)) { toastMessage = nil }
        }
    }
}

// MARK: - Nav bar

private struct NavBar: View {
    let onClose: () -> Void

    var body: some View {
        HStack {
            Text("Advanced setup")
                .font(NoteFont.titleS)
                .foregroundStyle(Color.noteInk)

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.noteInkDim)
                    .frame(width: 32, height: 32)
                    .background(Color.noteAlt, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Space.gutterH)
        .padding(.top, 44)
        .padding(.bottom, Space.s)
    }
}

// MARK: - Hero

private struct Hero: View {
    var body: some View {
        Text("Bring your own keys.")
            .font(NoteFont.displayL)
            .foregroundStyle(Color.noteInk)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Sub text

private struct SubText: View {
    var body: some View {
        Text("NO.TE uses Nostr keys for identity and encrypted backup. Skip this to let us generate a new pair — you can always change later.")
            .font(Font.custom("Inter Tight", size: 13.5, relativeTo: .callout))
            .foregroundStyle(Color.noteInkDim)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Option row

private struct OptionRow: View {
    let title: String
    let caption: String
    var badge: String? = nil
    var recommended: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Space.m) {
                VStack(alignment: .leading, spacing: Space.xs) {
                    HStack(spacing: Space.m) {
                        Text(title)
                            .font(NoteFont.body.weight(.medium))
                            .foregroundStyle(Color.noteInk)

                        if let badge {
                            Text(badge)
                                .font(NoteFont.micro)
                                .foregroundStyle(Color.noteInkDim)
                                .padding(.horizontal, Space.xs)
                                .padding(.vertical, 2)
                                .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.s))
                        }
                    }

                    Text(caption)
                        .font(Font.custom("Inter Tight", size: 12.5, relativeTo: .caption))
                        .foregroundStyle(Color.noteInkDim)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.noteInkMute)
                    .padding(.top, 2)
            }
            .padding(Space.xl)
            .background(Color.noteBg, in: RoundedRectangle(cornerRadius: Radius.xl))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.xl)
                    .strokeBorder(recommended ? Color.noteInk : Color.noteRule,
                                  lineWidth: recommended ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Footer

private struct Footer: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text("Your nsec never leaves this device unencrypted.")
                .font(NoteFont.captionS)
                .foregroundStyle(Color.noteInkMute)
            Text("Built on Nostr. An open protocol.")
                .font(NoteFont.captionS)
                .foregroundStyle(Color.noteInkMute)
        }
        .padding(.top, Space.m)
    }
}

// MARK: - Toast

private struct Toast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(NoteFont.captionS)
            .foregroundStyle(Color.noteInk)
            .padding(.horizontal, Space.l)
            .padding(.vertical, Space.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.m))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.m)
                    .strokeBorder(Color.noteRule, lineWidth: 1)
            )
            .composeShadow()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdvancedSetupView()
    }
}
