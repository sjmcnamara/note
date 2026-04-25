import SwiftUI

// MARK: - KeyImportView

struct KeyImportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var identityService: IdentityService
    @State private var nsec: String = ""
    @State private var validation: NsecValidator.Result = .empty
    @State private var validateTask: Task<Void, Never>?
    @State private var toastMessage: String?
    var onImported: (() -> Void)?

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                NavBar { dismiss() }

                ScrollView {
                    VStack(alignment: .leading, spacing: Space.sectionGap) {
                        PasteField(nsec: $nsec)
                        OrDivider()
                        QRRow { showToast("QR scanner lands later.") }
                        if case let .valid(npub, _) = validation {
                            DerivedKeyCard(npub: npub)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        } else if case .invalid = validation {
                            InvalidNote()
                                .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, Space.gutterH)
                    .padding(.top, Space.l)
                    .padding(.bottom, Space.sectionGap * 2)
                    .animation(.easeInOut(duration: 0.18), value: validation)
                }

                BottomActions(
                    canConfirm: validation.isValid,
                    onCancel: { dismiss() },
                    onConfirm: confirm
                )
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
        .onChange(of: nsec) { _, newValue in
            scheduleValidation(for: newValue)
        }
    }

    // MARK: - Actions

    private func scheduleValidation(for input: String) {
        validateTask?.cancel()
        validateTask = Task {
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else { return }
            let result = NsecValidator.validate(input)
            await MainActor.run { validation = result }
        }
    }

    private func confirm() {
        guard case .valid = validation else { return }
        do {
            try identityService.importKey(nsec: nsec.trimmingCharacters(in: .whitespacesAndNewlines))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            if let onImported { onImported() } else { dismiss() }
        } catch {
            showToast("Couldn't import key. Check the nsec and try again.")
        }
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
            Button(action: onClose) {
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
    }
}

// MARK: - Paste field

private struct PasteField: View {
    @Binding var nsec: String
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text("Paste your nsec")
                .font(NoteFont.captionS)
                .foregroundStyle(Color.noteInkMute)

            TextField("nsec1…", text: $nsec, axis: .vertical)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Color.noteInk)
                .tint(Color.noteInk)
                .lineLimit(2...4)
                .focused($focused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityLabel("Secret key input, paste or scan")
                .padding(Space.l)
                .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.xl))
        }
    }
}

// MARK: - Or divider

private struct OrDivider: View {
    var body: some View {
        HStack(spacing: Space.l) {
            Rectangle().fill(Color.noteRule).frame(height: 1)
            Text("or")
                .font(NoteFont.captionS)
                .foregroundStyle(Color.noteInkMute)
            Rectangle().fill(Color.noteRule).frame(height: 1)
        }
        .padding(.vertical, Space.xs)
    }
}

// MARK: - QR row

private struct QRRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.l) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.noteInk)
                    .frame(width: 44, height: 44)
                    .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.m))

                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text("Scan QR")
                        .font(NoteFont.body.weight(.medium))
                        .foregroundStyle(Color.noteInk)
                    Text("From another signer app")
                        .font(NoteFont.captionS)
                        .foregroundStyle(Color.noteInkMute)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.noteInkMute)
            }
            .padding(.vertical, Space.s)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Derived key card

private struct DerivedKeyCard: View {
    let npub: String

    private var shortNpub: String {
        guard npub.count > 16 else { return npub }
        return String(npub.prefix(12)) + "…" + String(npub.suffix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            HStack(spacing: Space.l) {
                IdentityAvatar(npub: npub)

                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text("Derived public key")
                        .font(NoteFont.captionS)
                        .foregroundStyle(Color.noteInkMute)
                    Text(shortNpub)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color.noteInkDim)
                        .lineLimit(1)
                }
            }

            HStack(spacing: Space.m) {
                ZStack {
                    Circle()
                        .fill(Color.noteOk.opacity(0.25))
                        .frame(width: 14, height: 14)
                    Circle()
                        .fill(Color.noteOk)
                        .frame(width: 7, height: 7)
                }
                Text("Key is valid")
                    .font(NoteFont.captionS)
                    .foregroundStyle(Color.noteInkDim)
            }
        }
        .padding(Space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.xxl))
    }
}

private struct InvalidNote: View {
    var body: some View {
        Text("Doesn't look like a valid nsec. Check for a missing character.")
            .font(NoteFont.captionS)
            .foregroundStyle(Color.noteInkMute)
            .padding(.horizontal, Space.l)
    }
}

// MARK: - Bottom actions

private struct BottomActions: View {
    let canConfirm: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        HStack(spacing: Space.l) {
            Button(action: onCancel) {
                Text("Cancel")
                    .font(NoteFont.body.weight(.medium))
                    .foregroundStyle(Color.noteInkDim)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background {
                        RoundedRectangle(cornerRadius: Radius.xl)
                            .strokeBorder(Color.noteRule, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            Button(action: onConfirm) {
                Text("Use this key")
                    .font(NoteFont.body.weight(.medium))
                    .foregroundStyle(canConfirm ? Color.noteBg : Color.noteInkMute)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        canConfirm ? Color.noteInk : Color.noteAlt,
                        in: RoundedRectangle(cornerRadius: Radius.xl)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canConfirm)
        }
        .padding(.horizontal, Space.gutterH)
        .padding(.bottom, 22)
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
        KeyImportView()
    }
    .environmentObject(IdentityService(storage: InMemorySecureStorage()))
}
