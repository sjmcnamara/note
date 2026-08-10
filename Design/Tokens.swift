import SwiftUI

// MARK: - Color
//
// Every accessor branches on `AppTheme.current`. In `.editorial` it returns the
// hand-picked asset-catalog colors; in `.native` it returns system semantic
// colors so the app inherits Apple's light/dark palette. Call sites are
// unchanged (`Color.noteBg`, …) — the root rebuilds the tree on theme switch,
// so these computed values re-resolve.

extension Color {
    private static func themed(_ asset: String, _ native: UIColor) -> Color {
        AppTheme.current == .native ? Color(uiColor: native) : Color(asset)
    }

    static var noteBg: Color      { themed("noteBg", .systemBackground) }
    static var noteAlt: Color     { themed("noteAlt", .secondarySystemBackground) }
    static var noteRule: Color    { themed("noteRule", .separator) }
    static var noteMuted: Color   { themed("noteMuted", .systemGray5) }
    static var noteInk: Color     { themed("noteInk", .label) }
    static var noteInkDim: Color  { themed("noteInkDim", .secondaryLabel) }
    static var noteInkMute: Color { themed("noteInkMute", .tertiaryLabel) }
    static var noteOk: Color      { themed("noteOk", .systemGreen) }

    /// Accent / call-to-action color. Editorial has no distinct accent (ink
    /// carries emphasis); native uses the system tint so buttons read as iOS.
    static var noteAccent: Color  { themed("noteInk", .tintColor) }
}

// MARK: - Typography

enum NoteFont {
    // Variable font family name — weights applied via .weight() (iOS 16+)
    private static let family       = "Inter Tight"
    private static let serifItalic  = "InstrumentSerif-Italic"

    private static var isNative: Bool { AppTheme.current == .native }

    /// Returns the editorial custom font, or the equivalent SF system font in
    /// native mode. Both scale with Dynamic Type via `relativeTo:`.
    private static func font(_ size: CGFloat, _ style: Font.TextStyle, _ weight: Font.Weight) -> Font {
        isNative
            ? Font.system(size: size, weight: weight).leading(.standard)
            : Font.custom(family, size: size, relativeTo: style).weight(weight)
    }

    static var displayXL: Font { font(34, .largeTitle, .bold) }
    static var displayL: Font  { font(28, .largeTitle, .bold) }
    static var display: Font   { font(26, .title, .semibold) }
    static var headline: Font  { font(22, .title2, .semibold) }
    static var titleM: Font    { font(16, .headline, .semibold) }
    static var titleS: Font    { font(15, .subheadline, .semibold) }
    static var body: Font      { font(14, .body, .regular) }
    static var bodyS: Font     { font(13, .callout, .regular) }
    static var caption: Font   { font(12, .caption, .regular) }
    static var captionS: Font  { font(11, .caption2, .regular) }
    static var micro: Font     { font(10, .caption2, .regular) }

    /// The one serif-italic "moment" per screen. Native keeps an elegant serif
    /// via the system serif design rather than the custom Instrument Serif.
    static func italic(_ size: CGFloat) -> Font {
        let style: Font.TextStyle
        switch size {
        case ..<14:   style = .caption
        case 14..<20: style = .body
        case 20..<28: style = .title2
        default:      style = .title
        }
        if isNative {
            return Font.system(size: size, weight: .regular, design: .serif).italic()
        }
        return Font.custom(serifItalic, size: size, relativeTo: style)
    }
}

// MARK: - Spacing

enum Space {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let s: CGFloat = 6
    static let m: CGFloat = 8
    static let base: CGFloat = 10
    static let l: CGFloat = 12
    static let xl: CGFloat = 14
    static let xxl: CGFloat = 18
    static let gutterH: CGFloat = 24
    static let sectionGap: CGFloat = 22
}

// MARK: - Radius

enum Radius {
    static let s: CGFloat = 6
    static let m: CGFloat = 8
    static let l: CGFloat = 10
    static let xl: CGFloat = 12
    static let xxl: CGFloat = 14
    static let pill: CGFloat = 99
    static let sheet: CGFloat = 22
}

// MARK: - Shadows

extension View {
    func composeShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 8)
            .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 2)
    }

    func sheetShadow() -> some View {
        self.shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: -10)
    }

    func paletteShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.18), radius: 25, x: 0, y: 10)
            .overlay(RoundedRectangle(cornerRadius: Radius.xl).stroke(Color.noteRule, lineWidth: 1))
    }
}

// MARK: - Motion

enum Motion {
    static let caretBlink: Double = 1.0
    static let toggleSwap: Double = 0.2
    static let sheetPresent: Double = 0.3
}
