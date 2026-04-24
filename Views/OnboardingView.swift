import SwiftUI

struct OnboardingView: View {
    @State private var showAdvanced = false
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingWordmark()
                .padding(.bottom, 28)

            OnboardingHero()
                .padding(.bottom, 16)

            OnboardingSubtext()
                .padding(.bottom, 32)

            OnboardingProofList()

            Spacer()

            PrimaryActionButton(title: "Start writing", action: generateAndEnter)
                .padding(.bottom, Space.m)

            PoweredByNostrFooter()
                .padding(.bottom, Space.sectionGap)
        }
        .padding(.top, 24)
        .padding(.horizontal, Space.gutterH)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func generateAndEnter() {
        _ = MockIdentity.generate()
        onComplete()
    }
}

// MARK: - Wordmark

private struct OnboardingWordmark: View {
    var body: some View {
        HStack(spacing: Space.m) {
            Circle()
                .fill(Color.noteInk)
                .frame(width: 8, height: 8)
            Text("NO.TE")
                .font(Font.custom("Inter Tight", size: 12, relativeTo: .caption).weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(Color.noteInk)
        }
    }
}

// MARK: - Hero

private struct OnboardingHero: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            // Added \n\n for paragraph look and bumped size to 44
            Text("Own your own words.")
                .font(NoteFont.italic(40)) 
                .foregroundStyle(Color.noteInk)
                .minimumScaleFactor(0.9)
                .multilineTextAlignment(.leading) // Keeps the "words" left-aligned
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Own your own words.")
    }
}
// MARK: - Subtext

private struct OnboardingSubtext: View {
    var body: some View {
        Text("A space for thoughts that are yours alone — written in your own words, kept on your own terms.")
            .font(NoteFont.titleS)
            .foregroundStyle(Color.noteInkDim)
            .frame(alignment: .leading)
            .minimumScaleFactor(1.1)
    }
}

// MARK: - Proof points

struct ProofPoint {
    let icon: String
    let title: String
    let body: String

    static let all: [ProofPoint] = [
        ProofPoint(
            icon: "internaldrive",
            title: "Local",
            body: "Notes stay on your device — not in the cloud, not on a platform, and not in some random data center."
        ),
        ProofPoint(
            icon: "eye.slash",
            title: "Private",
            body: "No signups, no emails, no profiling. You don't need permission to have a voice."
        ),
        ProofPoint(
            icon: "lock.shield",
            title: "Encrypted",
            body: "Secure your backup with a key only you control — then restore your notes on any new device."
        ),
    ]
}

private struct OnboardingProofList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Space.sectionGap) {
            ForEach(ProofPoint.all, id: \.title) { point in
                OnboardingProofRow(point: point)
            }
        }
    }
}

private struct OnboardingProofRow: View {
    let point: ProofPoint

    var body: some View {
        HStack(alignment: .top, spacing: Space.xxl) {
            Image(systemName: point.icon)
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(Color.noteInkDim)
                .frame(width: 22, alignment: .leading)

            VStack(alignment: .leading, spacing: Space.xs) {
                Text(point.title)
                    .font(Font.custom("Inter Tight", size: 15, relativeTo: .subheadline).weight(.semibold))
                    .foregroundStyle(Color.noteInk)
                    .minimumScaleFactor(0.9)
                Text(point.body)
                    .font(NoteFont.body)
                    .foregroundStyle(Color.noteInkDim)
                    .minimumScaleFactor(0.9)
            }
        }
    }
}

// MARK: - CTA

struct PrimaryActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(NoteFont.titleM)
                .scaleEffect(1.1)
                .foregroundStyle(Color.noteBg)
                .padding(.horizontal, 100) // Gives it a nice width without being full-screen
                .frame(height: 54)        // Slightly taller feels more premium
                .background(Color.noteInk, in: RoundedRectangle(cornerRadius: Radius.xl))
        }
        .buttonStyle(.plain)
        // Center the button since it's no longer full-width
        .frame(maxWidth: .infinity, alignment: .center) 
    }
}
struct OPrimaryActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(NoteFont.titleM)
                .scaleEffect(1.1)      // Scaling just the text inside is safer
                .foregroundStyle(Color.noteBg)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.noteInk, in: RoundedRectangle(cornerRadius: Radius.xl))
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryActionLink: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font.custom("Inter Tight", size: 12.5, relativeTo: .caption))
                .foregroundStyle(Color.noteInkDim)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .multilineTextAlignment(.center)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Footer

struct PoweredByNostrFooter: View {
    var body: some View {
        Text("Built on Nostr.")
            .font(NoteFont.caption)
            .foregroundStyle(Color.noteInkMute)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}
