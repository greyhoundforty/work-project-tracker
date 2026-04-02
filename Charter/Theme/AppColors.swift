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
}
