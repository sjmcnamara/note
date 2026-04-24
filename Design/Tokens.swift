import SwiftUI

// MARK: - Color

extension Color {
    static let noteBg      = Color("noteBg")
    static let noteAlt     = Color("noteAlt")
    static let noteRule    = Color("noteRule")
    static let noteMuted   = Color("noteMuted")
    static let noteInk     = Color("noteInk")
    static let noteInkDim  = Color("noteInkDim")
    static let noteInkMute = Color("noteInkMute")
    static let noteOk      = Color("noteOk")
}

// MARK: - Typography

enum NoteFont {
    // Variable font family name — weights applied via .weight() (iOS 16+)
    private static let family       = "Inter Tight"
    private static let serifItalic  = "InstrumentSerif-Italic"

    static let displayXL = Font.custom(family, size: 34, relativeTo: .largeTitle).weight(.medium)
    static let displayL  = Font.custom(family, size: 28, relativeTo: .largeTitle).weight(.medium)
    static let display   = Font.custom(family, size: 26, relativeTo: .title).weight(.medium)
    static let headline  = Font.custom(family, size: 22, relativeTo: .title2).weight(.medium)
    static let titleM    = Font.custom(family, size: 16, relativeTo: .headline).weight(.medium)
    static let titleS    = Font.custom(family, size: 15, relativeTo: .subheadline).weight(.medium)
    static let body      = Font.custom(family, size: 14, relativeTo: .body)
    static let bodyS     = Font.custom(family, size: 13, relativeTo: .callout)
    static let caption   = Font.custom(family, size: 12, relativeTo: .caption)
    static let captionS  = Font.custom(family, size: 11, relativeTo: .caption2)
    static let micro     = Font.custom(family, size: 10, relativeTo: .caption2)

    static func italic(_ size: CGFloat) -> Font {
        let style: Font.TextStyle
        switch size {
        case ..<14:   style = .caption
        case 14..<20: style = .body
        case 20..<28: style = .title2
        default:      style = .title
        }
        return Font.custom(serifItalic, size: size, relativeTo: style)
    }
}

// MARK: - Spacing

enum Space {
    static let xxs: CGFloat = 2
    static let xs:  CGFloat = 4
    static let s:   CGFloat = 6
    static let m:   CGFloat = 8
    static let base: CGFloat = 10
    static let l:   CGFloat = 12
    static let xl:  CGFloat = 14
    static let xxl: CGFloat = 18
    static let gutterH: CGFloat = 24
    static let sectionGap: CGFloat = 22
}

// MARK: - Radius

enum Radius {
    static let s:   CGFloat = 6
    static let m:   CGFloat = 8
    static let l:   CGFloat = 10
    static let xl:  CGFloat = 12
    static let xxl: CGFloat = 14
    static let pill: CGFloat = 99
    static let sheet: CGFloat = 22
}

// MARK: - Shadows

extension View {
    func composeShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 8)
            .shadow(color: .black.opacity(0.04), radius: 3,  x: 0, y: 2)
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

