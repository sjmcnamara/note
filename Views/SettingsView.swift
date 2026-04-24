import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.sectionGap) {
                SettingsNavBar()
                AppearancePicker()
                TextSizeRow()
                NavCard()
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

// MARK: - Text size row

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

// MARK: - Nav card

private struct NavCard: View {
    var body: some View {
        VStack(spacing: 0) {
            NavigationLink { AboutView() } label: {
                navRow(label: "About")
            }
            .buttonStyle(.plain)

            Rectangle().fill(Color.noteRule).frame(height: 1)

            NavigationLink { AdvancedSettingsView() } label: {
                navRow(label: "Advanced")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Space.xl)
        .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.xxl))
    }

    @ViewBuilder
    private func navRow(label: String) -> some View {
        HStack {
            Text(label)
                .font(NoteFont.body)
                .foregroundStyle(Color.noteInk)
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
        SettingsView()
    }
    .environmentObject(AppSettings.shared)
}
