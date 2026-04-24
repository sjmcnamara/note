import SwiftUI
import LocalAuthentication

// MARK: - SettingsView

struct SettingsView: View {
    var identity: any NostrIdentity = MockIdentity()
    var backup: MockBackup = MockBackup()
    @State private var revealNsec = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.sectionGap) {
                SettingsNavBar()
                IdentityCard(identity: identity, revealNsec: $revealNsec)
                AppearancePicker()
                SettingRows()
                PrivateBackupCard(backup: backup)
                FooterWordmark()
            }
            .padding(.horizontal, Space.gutterH)
            .padding(.bottom, Space.sectionGap * 2)
        }
        .background(Color.noteBg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Nav bar

private struct SettingsNavBar: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: Space.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                    Text("NO.TE")
                        .font(NoteFont.caption)
                }
                .foregroundStyle(Color.noteInkDim)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(NoteFont.titleS)
                .foregroundStyle(Color.noteInk)
        }
        .padding(.top, 44)
        .padding(.bottom, Space.s)
    }
}

// MARK: - Identity card

private struct IdentityCard: View {
    let identity: any NostrIdentity
    @Binding var revealNsec: Bool
    @State private var hideTask: Task<Void, Never>?
    @State private var copyConfirmed = false

    private var shortNpub: String {
        let n = identity.npub
        guard n.count > 16 else { return n }
        return String(n.prefix(12)) + "…" + String(n.suffix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            IdentityAvatar(npub: identity.npub)

            VStack(alignment: .leading, spacing: Space.xs) {
                Text("Public key · npub")
                    .font(NoteFont.captionS)
                    .foregroundStyle(Color.noteInkMute)

                HStack(spacing: Space.m) {
                    Text(shortNpub)
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
                Text("nsec · hidden")
                    .font(NoteFont.captionS)
                    .foregroundStyle(Color.noteInkMute)

                HStack(spacing: Space.m) {
                    Image(systemName: "lock")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.noteInkMute)

                    Group {
                        if revealNsec {
                            Text(identity.nsec)
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
                            withAnimation { revealNsec = false }
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

            HStack(spacing: 0) {
                Text("Your secret key never leaves this device. ")
                    .font(NoteFont.captionS)
                    .foregroundStyle(Color.noteInkMute)
                Text("Back up now")
                    .font(NoteFont.captionS)
                    .foregroundStyle(Color.noteInkMute)
                    .underline()
            }
        }
        .padding(Space.xl)
        .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.xxl))
    }

    private func authenticate() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            withAnimation { revealNsec = true }
            scheduleHide()
            return
        }
        ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                           localizedReason: "Reveal your secret key") { ok, _ in
            guard ok else { return }
            DispatchQueue.main.async {
                withAnimation { revealNsec = true }
                scheduleHide()
            }
        }
    }

    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled else { return }
            await MainActor.run { withAnimation { revealNsec = false } }
        }
    }
}

private struct IdentityAvatar: View {
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

// MARK: - Appearance picker

private struct AppearancePicker: View {
    @AppStorage("appearance") private var appearanceRaw = "system"

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            Text("Appearance")
                .font(NoteFont.captionS)
                .foregroundStyle(Color.noteInkMute)

            HStack(spacing: Space.l) {
                AppearanceTile(label: "Light",  scheme: "light",  active: appearanceRaw == "light")  { appearanceRaw = "light" }
                AppearanceTile(label: "Night",  scheme: "dark",   active: appearanceRaw == "dark")   { appearanceRaw = "dark" }
                AppearanceTile(label: "System", scheme: "system", active: appearanceRaw == "system") { appearanceRaw = "system" }
            }
        }
    }
}

private struct AppearanceTile: View {
    let label: String
    let scheme: String
    let active: Bool
    let action: () -> Void

    private var tileBg: Color {
        switch scheme {
        case "light": return Color(white: 0.98)
        case "dark":  return Color(white: 0.10)
        default:      return Color.noteAlt
        }
    }

    private var lineColor: Color {
        scheme == "dark" ? Color.white.opacity(0.35) : Color.black.opacity(0.20)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: Space.s) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: Radius.m)
                        .fill(tileBg)
                        .frame(height: 64)

                    VStack(alignment: .leading, spacing: 4) {
                        Capsule().fill(lineColor).frame(width: 28, height: 3)
                        Capsule().fill(lineColor.opacity(0.5)).frame(width: 20, height: 2)
                        Capsule().fill(lineColor.opacity(0.5)).frame(width: 24, height: 2)
                    }
                    .padding(Space.base)
                }
                .clipShape(RoundedRectangle(cornerRadius: Radius.m))
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.m)
                        .strokeBorder(active ? Color.noteInk : Color.noteRule, lineWidth: active ? 2 : 1)
                }

                Text(label)
                    .font(NoteFont.captionS)
                    .foregroundStyle(active ? Color.noteInk : Color.noteInkMute)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Settings rows

private struct SettingRows: View {
    @AppStorage("tagSuggestions") private var tagSuggestions = true
    @AppStorage("morningPrompt")  private var morningPrompt  = false
    @Environment(AppSettings.self) private var settings

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Space.xs) {
                HStack {
                    Text("Text size")
                        .font(NoteFont.body)
                        .foregroundStyle(Color.noteInk)
                    Spacer()
                    Text(textSizeLabel)
                        .font(NoteFont.captionS)
                        .foregroundStyle(Color.noteInkMute)
                        .monospacedDigit()
                }
                Slider(
                    value: Binding(
                        get: { Double(settings.textSizeStep) },
                        set: { settings.textSizeStep = Int($0.rounded()) }
                    ),
                    in: -3...3,
                    step: 1
                )
                .tint(Color.noteInk)
            }
            .padding(.vertical, Space.l)

            Rectangle().fill(Color.noteRule).frame(height: 1)

            settingsRow {
                Text("Tag suggestions")
                    .font(NoteFont.body)
                    .foregroundStyle(Color.noteInk)
                Spacer()
                Toggle("", isOn: $tagSuggestions)
                    .labelsHidden()
                    .tint(Color.noteInk)
            }

            Rectangle().fill(Color.noteRule).frame(height: 1)

            settingsRow {
                Text("Morning prompt")
                    .font(NoteFont.body)
                    .foregroundStyle(Color.noteInk)
                Spacer()
                Toggle("", isOn: $morningPrompt)
                    .labelsHidden()
                    .tint(Color.noteInk)
            }
        }
    }

    @ViewBuilder
    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack { content() }
            .padding(.vertical, Space.l)
    }

    private var textSizeLabel: String {
        switch settings.textSizeStep {
        case ..<0: return "Small"
        case 1...: return "Large"
        default:   return "Default"
        }
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

// MARK: - Footer

private struct FooterWordmark: View {
    var body: some View {
        Text("NO.TE · Powered by Nostr · open protocol")
            .font(.custom("Inter Tight", size: 10.5))
            .foregroundStyle(Color.noteInkMute)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, Space.m)
            .padding(.bottom, Space.l)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppSettings())
}
