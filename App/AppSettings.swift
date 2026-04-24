import Foundation

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var textSizeStep: Int = UserDefaults.standard.integer(forKey: "textSizeStep") {
        didSet { UserDefaults.standard.set(textSizeStep, forKey: "textSizeStep") }
    }

    private init() {}
}
