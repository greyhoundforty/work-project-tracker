import SwiftUI

// Gruvbox Light and Dark Medium palettes
// https://github.com/morhetz/gruvbox
extension Color {

    // MARK: - Backgrounds

    /// Main window background
    static var gruvBg: Color          { Color("gruvBg") }
    /// Sidebar / panel background
    static var gruvBg1: Color         { Color("gruvBg1") }
    /// Selected row / elevated surface
    static var gruvBg2: Color         { Color("gruvBg2") }
    /// Dividers / subtle borders
    static var gruvBg3: Color         { Color("gruvBg3") }

    // MARK: - Foregrounds

    static var gruvFg: Color          { Color("gruvFg") }
    static var gruvFg2: Color         { Color("gruvFg2") }
    static var gruvFgDim: Color       { Color("gruvFgDim") }

    // MARK: - Accent colors

    static var gruvRed: Color         { Color("gruvRed") }
    static var gruvGreen: Color       { Color("gruvGreen") }
    static var gruvYellow: Color      { Color("gruvYellow") }
    static var gruvBlue: Color        { Color("gruvBlue") }
    static var gruvPurple: Color      { Color("gruvPurple") }
    static var gruvAqua: Color        { Color("gruvAqua") }
    static var gruvOrange: Color      { Color("gruvOrange") }
}

extension Color {
    /// Returns the Gruvbox accent color for a given project stage.
    static func gruvStageColor(for stage: ProjectStage) -> Color {
        switch stage {
        case .discovery:       return .gruvAqua
        case .initialDelivery: return .gruvYellow
        case .refine:          return .gruvOrange
        case .proposal:        return .gruvRed
        case .won:             return .gruvGreen
        case .lost:            return .gruvRed
        }
    }
}
