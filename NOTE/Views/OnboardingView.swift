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

            Spacer(minLength: Space.xxl)

            PrimaryActionButton(title: "Start writing", action: generateAndEnter)
                .padding(.bottom, Space.m)

            SecondaryActionLink(
                title: "Advanced setup — keys, relays, import",
                action: { showAdvanced = true }
            )
            .padding(.bottom, Space.l)

            PoweredByNostrFooter()
                .padding(.bottom, Space.sectionGap)
        }
        .padding(.top, 24)
        .padding(.horizontal, Space.gutterH)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.noteBg.ignoresSafeArea())
        .sheet(isPresented: $showAdvanced) {
            AdvancedSetupView()
                .presentationDetents([.large])
        }
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
                .font(Font.custom("Inter Tight", size: 12).weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(Color.noteInk)
        }
    }
}

// MARK: - Hero

private struct OnboardingHero: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text("Own your words.")
                .font(NoteFont.displayXL)
                .foregroundStyle(Color.noteInk)
                .minimumScaleFactor(0.9)
            Text("yours alone.")
                .font(NoteFont.italic(40))
                .foregroundStyle(Color.noteInk)
                .minimumScaleFactor(0.9)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Own your words — yours alone")
    }
}

// MARK: - Subtext

private struct OnboardingSubtext: View {
    var body: some View {
        Text("Everything stays on this device. Nothing leaves unless you ask it to.")
            .font(NoteFont.body)
            .foregroundStyle(Color.noteInkDim)
            .frame(maxWidth: 260, alignment: .leading)
            .minimumScaleFactor(0.9)
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
            body: "Notes live on your device, and works perfectly offline. No account required."
        ),
        ProofPoint(
            icon: "eye.slash",
            title: "Privacy",
            body: "No trackers, no analytics, no ads — ever."
        ),
        ProofPoint(
            icon: "lock.shield",
            title: "Encrypted backup · optional",
            body: "Encrypt a backup with a key only you hold. Recover your notes to a new device."
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
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Color.noteInkDim)
                .frame(width: 22, alignment: .leading)

            VStack(alignment: .leading, spacing: Space.xs) {
                Text(point.title)
                    .font(Font.custom("Inter Tight", size: 13.5).weight(.semibold))
                    .foregroundStyle(Color.noteInk)
                    .minimumScaleFactor(0.9)
                Text(point.body)
                    .font(Font.custom("Inter Tight", size: 12.5))
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
                .font(NoteFont.titleS)
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
                .font(Font.custom("Inter Tight", size: 12.5))
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
        Text("Powered by Nostr · open protocol")
            .font(Font.custom("Inter Tight", size: 10.5))
            .foregroundStyle(Color.noteInkMute)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}
