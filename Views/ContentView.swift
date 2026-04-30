import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var onboardingComplete = false
    @AppStorage("appearance") private var appearanceRaw = "system"
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var lockService: AppLockService
    @Environment(\.scenePhase) private var scenePhase

    private var colorScheme: ColorScheme? {
        switch appearanceRaw {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    private var typeSize: DynamicTypeSize {
        switch settings.textSizeStep {
        case -3: return .xSmall
        case -2: return .small
        case -1: return .medium
        case  1: return .xLarge
        case  2: return .xxLarge
        case  3: return .xxxLarge
        default: return .large
        }
    }

    var body: some View {
        ZStack {
            Group {
                if onboardingComplete {
                    TimelineView()
                } else {
                    OnboardingView(onComplete: { onboardingComplete = true })
                }
            }

            if lockService.lockEnabled && lockService.isLocked {
                LockOverlayView()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(colorScheme)
        .dynamicTypeSize(typeSize)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                lockService.lockIfEnabled()
            } else if phase == .active {
                lockService.evaluateIfNeeded()
            }
        }
    }
}

#Preview {
    ContentView()
}
