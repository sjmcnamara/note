import SwiftUI
import LocalAuthentication

// MARK: - AdvancedSettingsView

struct AdvancedSettingsView: View {
    @EnvironmentObject private var identityService: IdentityService
    var backup: MockBackup = MockBackup()
    @State private var revealNsec = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.sectionGap) {
                AdvancedNavBar()
                if let identity = identityService.identity {
                    IdentityCard(identity: identity, revealNsec: $revealNsec)
                }
                PrivateBackupCard(backup: backup)
                KeyActionsCard()
            }
            .padding(.horizontal, Space.gutterH)
            .padding(.bottom, Space.sectionGap * 2)
        }
        .background(Color.noteBg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Nav bar

private struct AdvancedNavBar: View {
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

            Text("Advanced")
                .font(NoteFont.titleS)
                .foregroundStyle(Color.noteInk)
        }
        .padding(.top, 44)
        .padding(.bottom, Space.s)
    }
}

// MARK: - Identity card

private struct IdentityCard: View {
    let identity: NostrIdentity
    @Binding var revealNsec: Bool
    @EnvironmentObject private var identityService: IdentityService
    @State private var hideTask: Task<Void, Never>?
    @State private var copyConfirmed = false
    @State private var revealedNsec: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            IdentityAvatar(npub: identity.npub)

            VStack(alignment: .leading, spacing: Space.xs) {
                Text("Public key (npub)")
                    .font(NoteFont.captionS)
                    .foregroundStyle(Color.noteInkMute)

                HStack(spacing: Space.m) {
                    Text(identity.shortNpub)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color.noteInkDim)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        UIPasteboard.general.string = identity.npub
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        withAnimation { copyConfirmed = true }
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            withAnimation { copyConfirmed = false }
                        }
                    } label: {
                        Text(copyConfirmed ? "Copied" : "Copy")
                            .font(NoteFont.captionS)
                            .foregroundStyle(Color.noteInkDim)
                            .padding(.horizontal, Space.base)
                            .padding(.vertical, Space.xs)
                            .background(Color.noteBg, in: RoundedRectangle(cornerRadius: Radius.s))
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: Space.xs) {
                Text("Secret key (nsec)")
                    .font(NoteFont.captionS)
                    .foregroundStyle(Color.noteInkMute)

                HStack(spacing: Space.m) {
                    Image(systemName: "lock")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.noteInkMute)

                    Group {
                        if revealNsec, let revealedNsec {
                            Text(revealedNsec)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(Color.noteInk)
                        } else {
                            Text(String(repeating: "•", count: 22))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Color.noteInkMute)
                        }
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        if revealNsec {
                            hideTask?.cancel()
                            withAnimation {
                                revealNsec = false
                                revealedNsec = nil
                            }
                        } else {
                            authenticate()
                        }
                    } label: {
                        Text(revealNsec ? "Hide" : "Reveal")
                            .font(NoteFont.captionS)
                            .foregroundStyle(Color.noteInkDim)
                            .padding(.horizontal, Space.base)
                            .padding(.vertical, Space.xs)
                            .background(Color.noteBg, in: RoundedRectangle(cornerRadius: Radius.s))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Secret key, hidden, double-tap to reveal")
                }
                .padding(Space.l)
                .background(Color.noteBg, in: RoundedRectangle(cornerRadius: Radius.m))
            }

            Text("Your secret key never leaves this device.")
                .font(NoteFont.captionS)
                .foregroundStyle(Color.noteInkMute)
        }
        .padding(Space.xl)
        .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.xxl))
    }

    private func authenticate() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            reveal()
            return
        }
        ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                           localizedReason: "Reveal your secret key") { ok, _ in
            guard ok else { return }
            DispatchQueue.main.async { reveal() }
        }
    }

    private func reveal() {
        guard let nsec = identityService.exportNsec() else { return }
        withAnimation {
            revealedNsec = nsec
            revealNsec = true
        }
        scheduleHide()
    }

    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation {
                    revealNsec = false
                    revealedNsec = nil
                }
            }
        }
    }
}

struct IdentityAvatar: View {
    let npub: String

    private var hue: Double {
        let hash = npub.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        return Double(abs(hash) % 360) / 360.0
    }

    var body: some View {
        Circle()
            .fill(
                AngularGradient(
                    colors: [
                        Color(hue: hue, saturation: 0.55, brightness: 0.90),
                        Color(hue: (hue + 0.33).truncatingRemainder(dividingBy: 1), saturation: 0.55, brightness: 0.90),
                        Color(hue: (hue + 0.67).truncatingRemainder(dividingBy: 1), saturation: 0.55, brightness: 0.90),
                        Color(hue: hue, saturation: 0.55, brightness: 0.90),
                    ],
                    center: .center
                )
            )
            .frame(width: 44, height: 44)
    }
}

// MARK: - Private backup card

private struct PrivateBackupCard: View {
    var backup: MockBackup
    @State private var enabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            HStack(spacing: Space.m) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.noteInkDim)

                Text("Private Backup")
                    .font(NoteFont.titleS)
                    .foregroundStyle(Color.noteInk)

                Text("E2EE")
                    .font(NoteFont.micro)
                    .foregroundStyle(Color.noteInkDim)
                    .padding(.horizontal, Space.xs)
                    .padding(.vertical, 2)
                    .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.s))

                Spacer()

                Toggle("", isOn: $enabled)
                    .labelsHidden()
                    .tint(Color.noteInk)
            }

            backupBody

            RelayRow(status: backup.status)

            HStack(spacing: Space.l) {
                OutlineButton(label: "Add relay") {}
                OutlineButton(label: "Restore") {}
            }
        }
        .padding(Space.xl)
        .background(Color.noteBg)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.xxl)
                .strokeBorder(Color.noteRule, lineWidth: 1)
        }
        .onChange(of: enabled) { _, on in
            Task {
                if on {
                    backup.status = .connecting
                    try? await Task.sleep(for: .milliseconds(800))
                    backup.status = .synced(lastAt: Date())
                } else {
                    backup.status = .disabled
                }
            }
        }
    }

    private var backupBody: some View {
        (
            Text("Encrypted with your ")
                .font(NoteFont.bodyS)
                .foregroundStyle(Color.noteInkDim)
            + Text("nsec")
                .font(NoteFont.italic(13))
                .foregroundStyle(Color.noteInkDim)
            + Text(". Only you can decrypt.")
                .font(NoteFont.bodyS)
                .foregroundStyle(Color.noteInkDim)
        )
    }
}

private struct RelayRow: View {
    let status: BackupStatus

    private var statusText: String {
        switch status {
        case .disabled:           return "Disabled"
        case .connecting:         return "Connecting…"
        case .syncing:            return "Syncing…"
        case .synced:             return "Synced"
        case .error(let message): return message
        }
    }

    private var dotColor: Color {
        switch status {
        case .synced: return .noteOk
        case .error:  return Color(white: 0.6)
        default:      return .noteInkMute
        }
    }

    var body: some View {
        HStack(spacing: Space.m) {
            ZStack {
                Circle()
                    .fill(dotColor.opacity(0.25))
                    .frame(width: 14, height: 14)
                Circle()
                    .fill(dotColor)
                    .frame(width: 7, height: 7)
            }

            Text("wss://relay.pub")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color.noteInkDim)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(statusText)
                .font(NoteFont.captionS)
                .foregroundStyle(Color.noteInkMute)
        }
        .padding(.horizontal, Space.l)
        .padding(.vertical, Space.base)
        .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.m))
    }
}

private struct OutlineButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(NoteFont.bodyS)
                .foregroundStyle(Color.noteInkDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Space.base)
                .background {
                    RoundedRectangle(cornerRadius: Radius.m)
                        .strokeBorder(Color.noteRule, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Key actions

private struct KeyActionsCard: View {
    var body: some View {
        VStack(spacing: 0) {
            NavigationLink { AdvancedSetupView() } label: {
                keyRow(label: "Change keys",
                       caption: "Generate new, or import an existing nsec")
            }
            .buttonStyle(.plain)

            Rectangle().fill(Color.noteRule).frame(height: 1)

            NavigationLink { AdvancedSetupView() } label: {
                keyRow(label: "Restore from backup",
                       caption: "Recover notes from a relay")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Space.xl)
        .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.xxl))
    }

    @ViewBuilder
    private func keyRow(label: String, caption: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Space.xxs) {
                Text(label)
                    .font(NoteFont.body)
                    .foregroundStyle(Color.noteInk)
                Text(caption)
                    .font(NoteFont.captionS)
                    .foregroundStyle(Color.noteInkMute)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.noteInkMute)
        }
        .padding(.vertical, Space.l)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdvancedSettingsView()
    }
    .environmentObject(IdentityService(storage: InMemorySecureStorage()))
}
