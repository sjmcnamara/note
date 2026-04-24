import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var onboardingComplete = false
    @AppStorage("appearance") private var appearanceRaw = "system"

    private var colorScheme: ColorScheme? {
        switch appearanceRaw {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some View {
        Group {
            if onboardingComplete {
                TimelineView()
            } else {
                OnboardingView(onComplete: { onboardingComplete = true })
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

#Preview {
    ContentView()
}
