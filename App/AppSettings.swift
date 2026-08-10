import Foundation

/// Visual style of the whole app. `editorial` is the original custom
/// paper/serif system; `native` swaps in system fonts, semantic colors, and
/// stock iOS chrome (large-title nav bars, inset-grouped lists).
enum AppTheme: String, CaseIterable {
    case editorial
    case native

    var label: String {
        switch self {
        case .editorial: return "Editorial"
        case .native:    return "Native"
        }
    }

    var blurb: String {
        switch self {
        case .editorial: return "The original paper-and-serif look."
        case .native:    return "Standard iOS fonts, colors, and navigation."
        }
    }

    /// Read by the static token accessors in Tokens.swift. Views can't inject
    /// environment into `Color.noteBg`-style statics, so the current theme is
    /// mirrored here; the root re-keys its content on change to force a rebuild.
    static var current: AppTheme = {
        let raw = UserDefaults.standard.string(forKey: "appTheme")
        return raw.flatMap(AppTheme.init(rawValue:)) ?? .editorial
    }()
}

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var textSizeStep: Int = UserDefaults.standard.integer(forKey: "textSizeStep") {
        didSet { UserDefaults.standard.set(textSizeStep, forKey: "textSizeStep") }
    }

    @Published var theme: AppTheme = AppTheme.current {
        didSet {
            AppTheme.current = theme
            UserDefaults.standard.set(theme.rawValue, forKey: "appTheme")
        }
    }

    private init() {}
}
