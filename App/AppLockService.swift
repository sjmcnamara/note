import SwiftUI
import LocalAuthentication

@MainActor
final class AppLockService: ObservableObject {
    static let shared = AppLockService()

    @AppStorage("lockEnabled") private(set) var lockEnabled = false
    @Published private(set) var isLocked = false

    private var evaluating = false

    private init() {}

    func setLockEnabled(_ enabled: Bool) {
        lockEnabled = enabled
        if !enabled { isLocked = false }
    }

    func lockIfEnabled() {
        guard lockEnabled else { return }
        isLocked = true
    }

    func evaluateIfNeeded() {
        guard lockEnabled, isLocked, !evaluating else { return }
        evaluating = true
        let ctx = LAContext()
        var err: NSError?
        let policy: LAPolicy = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication
        ctx.evaluatePolicy(policy, localizedReason: "Unlock NO.TE") { [weak self] ok, _ in
            DispatchQueue.main.async {
                self?.evaluating = false
                if ok { self?.isLocked = false }
            }
        }
    }
}
