import SwiftUI

struct ContentView: View {
    @State private var onboardingComplete = false

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
