import SwiftUI

// Light: Bluloco-inspired  https://github.com/uloco/theme-bluloco-light
// Dark:  Gruvbox Medium     https://github.com/morhetz/gruvbox
extension Color {

    // MARK: - Backgrounds

    /// Main window background
    static var themeBg: Color          { Color("themeBg") }
    /// Sidebar / panel background
    static var themeBg1: Color         { Color("themeBg1") }
    /// Selected row / elevated surface
    static var themeBg2: Color         { Color("themeBg2") }
    /// Dividers / subtle borders
    static var themeBg3: Color         { Color("themeBg3") }

    // MARK: - Foregrounds

    static var themeFg: Color          { Color("themeFg") }
    static var themeFg2: Color         { Color("themeFg2") }
    static var themeFgDim: Color       { Color("themeFgDim") }

    // MARK: - Accent colors

    static var themeRed: Color         { Color("themeRed") }
    static var themeGreen: Color       { Color("themeGreen") }
    static var themeYellow: Color      { Color("themeYellow") }
    static var themeBlue: Color        { Color("themeBlue") }
    static var themePurple: Color      { Color("themePurple") }
    static var themeAqua: Color        { Color("themeAqua") }
    static var themeOrange: Color      { Color("themeOrange") }
}

extension Color {
    /// Returns the accent color for a given project stage.
    static func themeStageColor(for stage: ProjectStage) -> Color {
        switch stage {
        case .discovery:       return .themeAqua
        case .initialDelivery: return .themeYellow
        case .refine:          return .themeOrange
        case .proposal:        return .themeRed
        case .won:             return .themeGreen
        case .lost:            return .themeRed
        }
    }

    /// Hex parser used by generated theme values.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r, g, b, a: Double
        switch cleaned.count {
        case 3:
            r = Double((value >> 8) & 0xF) / 15.0
            g = Double((value >> 4) & 0xF) / 15.0
            b = Double(value & 0xF) / 15.0
            a = 1.0
        case 6:
            r = Double((value >> 16) & 0xFF) / 255.0
            g = Double((value >> 8) & 0xFF) / 255.0
            b = Double(value & 0xFF) / 255.0
            a = 1.0
        case 8:
            r = Double((value >> 24) & 0xFF) / 255.0
            g = Double((value >> 16) & 0xFF) / 255.0
            b = Double((value >> 8) & 0xFF) / 255.0
            a = Double(value & 0xFF) / 255.0
        default:
            r = 0
            g = 0
            b = 0
            a = 1.0
        }

        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
