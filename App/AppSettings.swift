import Foundation
import Observation

@Observable
final class AppSettings {
    var textSizeStep: Int = 0 {
        didSet { UserDefaults.standard.set(textSizeStep, forKey: "textSizeStep") }
    }

    init() {
        textSizeStep = UserDefaults.standard.integer(forKey: "textSizeStep")
    }
}
