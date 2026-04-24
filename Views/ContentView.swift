import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var onboardingComplete = false
    @AppStorage("appearance") private var appearanceRaw = "system"
    @AppStorage("textSizeStep") private var textSizeStep = 0

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
        .environment(\.textSizeStep, textSizeStep)
    }
}

#Preview {
    ContentView()
}
