import SwiftUI

struct ContentView: View {
    @State private var onboardingComplete = false

    var body: some View {
        if onboardingComplete {
            TimelinePlaceholderView()
        } else {
            OnboardingView(onComplete: { onboardingComplete = true })
        }
    }
}

// Placeholder — replaced by TimelineView in the next PR.
private struct TimelinePlaceholderView: View {
    var body: some View {
        VStack(spacing: Space.xxl) {
            Text("NO.TE")
                .font(NoteFont.headline)
                .tracking(0.8)
                .foregroundStyle(Color.noteInk)
            Text("Timeline coming next.")
                .font(NoteFont.body)
                .foregroundStyle(Color.noteInkDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.noteBg.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
}
