import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject private var identityService: IdentityService
    @EnvironmentObject private var lockService: AppLockService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.sectionGap) {
                SettingsNavBar()
                IdentitySection()
                AppearanceSection()
                AdvancedNavCard(lockService: lockService)
                AboutNavCard()
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

// MARK: - Identity section

private struct IdentitySection: View {
    @EnvironmentObject private var identityService: IdentityService

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            SectionLabel("Identity")
            if let identity = identityService.identity {
                IdentityRow(identity: identity)
            }
        }
    }
}

private struct IdentityRow: View {
    let identity: NostrIdentity
    @State private var copyConfirmed = false

    var body: some View {
        HStack(spacing: Space.l) {
            IdentityAvatar(npub: identity.npub)

            VStack(alignment: .leading, spacing: Space.xxs) {
                Text("Public key · npub")
                    .font(NoteFont.captionS)
                    .foregroundStyle(Color.noteInkMute)
                Text(identity.shortNpub)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color.noteInkDim)
                    .lineLimit(1)
            }
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
        .padding(Space.l)
        .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.xxl))
    }
}

// MARK: - Appearance section

private struct AppearanceSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            SectionLabel("Appearance")
            AppearancePicker()
            TextSizeRow()
        }
    }
}

private struct AppearancePicker: View {
    @AppStorage("appearance") private var appearanceRaw = "system"

    var body: some View {
        HStack(spacing: Space.l) {
            AppearanceTile(label: "Light",  scheme: "light",  active: appearanceRaw == "light")  { appearanceRaw = "light" }
            AppearanceTile(label: "Night",  scheme: "dark",   active: appearanceRaw == "dark")   { appearanceRaw = "dark" }
            AppearanceTile(label: "System", scheme: "system", active: appearanceRaw == "system") { appearanceRaw = "system" }
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

private struct TextSizeRow: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
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
    }

    private var textSizeLabel: String {
        switch settings.textSizeStep {
        case -3: return "X-Small"
        case -2: return "Smaller"
        case -1: return "Small"
        case  1: return "Large"
        case  2: return "Larger"
        case  3: return "X-Large"
        default: return "Default"
        }
    }
}

// MARK: - Advanced nav card (includes Lock toggle)

private struct AdvancedNavCard: View {
    @ObservedObject var lockService: AppLockService

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            SectionLabel("Advanced")
            VStack(spacing: 0) {
                NavigationLink { AdvancedSettingsView() } label: {
                    navRow(label: "Keys & Backup",
                           caption: "Identity, nsec, private relay")
                }
                .buttonStyle(.plain)

                Rectangle().fill(Color.noteRule).frame(height: 1)

                HStack {
                    VStack(alignment: .leading, spacing: Space.xxs) {
                        Text("Lock with Face ID")
                            .font(NoteFont.body)
                            .foregroundStyle(Color.noteInk)
                        Text("Require Face ID or passcode on open")
                            .font(NoteFont.captionS)
                            .foregroundStyle(Color.noteInkMute)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { lockService.lockEnabled },
                        set: { lockService.setLockEnabled($0) }
                    ))
                    .labelsHidden()
                    .tint(Color.noteInk)
                }
                .padding(.vertical, Space.l)
            }
            .padding(.horizontal, Space.xl)
            .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.xxl))
        }
    }

    @ViewBuilder
    private func navRow(label: String, caption: String) -> some View {
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

// MARK: - About nav card

private struct AboutNavCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            SectionLabel("About")
            VStack(spacing: 0) {
                NavigationLink { AboutView() } label: {
                    HStack {
                        Text("About NO.TE")
                            .font(NoteFont.body)
                            .foregroundStyle(Color.noteInk)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.noteInkMute)
                    }
                    .padding(.vertical, Space.l)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Space.xl)
            .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.xxl))
        }
    }
}

// MARK: - Shared section label

private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(NoteFont.captionS)
            .foregroundStyle(Color.noteInkMute)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(AppSettings.shared)
    .environmentObject(IdentityService(storage: InMemorySecureStorage()))
    .environmentObject(AppLockService.shared)
}
