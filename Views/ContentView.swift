import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var onboardingComplete = false

    var body: some View {
        if onboardingComplete {
            TimelineView()
        } else {
            OnboardingView(onComplete: { onboardingComplete = true })
        }
    }
}

#Preview {
    ContentView()
}
