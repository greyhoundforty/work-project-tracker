import SwiftUI
import SwiftThemeKit

// MARK: - Generated ThemeColors

let lightColors = ThemeColors(
  primary: .init(hex: "#215fa7"),
  onPrimary: .init(hex: "#ffffff"),
  primaryContainer: .init(hex: "#d5e3ff"),
  onPrimaryContainer: .init(hex: "#004788"),
  secondary: .init(hex: "#555f71"),
  onSecondary: .init(hex: "#ffffff"),
  secondaryContainer: .init(hex: "#d9e3f8"),
  onSecondaryContainer: .init(hex: "#3d4758"),
  tertiary: .init(hex: "#6e5676"),
  onTertiary: .init(hex: "#ffffff"),
  tertiaryContainer: .init(hex: "#f8d8fe"),
  onTertiaryContainer: .init(hex: "#553e5d"),
  background: .init(hex: "#fdfbff"),
  onBackground: .init(hex: "#1a1c1e"),
  error: .init(hex: "#ba1a1a"),
  onError: .init(hex: "#ffffff"),
  errorContainer: .init(hex: "#ffdad6"),
  onErrorContainer: .init(hex: "#93000a"),
  inverseSurface: .init(hex: "#2f3033"),
  inverseOnSurface: .init(hex: "#f1f0f4"),
  inversePrimary: .init(hex: "#a7c8ff"),
  surface: .init(hex: "#faf9fd"),
  onSurface: .init(hex: "#1a1c1e"),
  surfaceVariant: .init(hex: "#e0e2ec"),
  onSurfaceVariant: .init(hex: "#43474e"),
  surfaceDim: .init(hex: "#dad9dd"),
  surfaceBright: .init(hex: "#faf9fd"),
  surfaceContainerLowest: .init(hex: "#ffffff"),
  surfaceContainerLow: .init(hex: "#f4f3f7"),
  surfaceContainer: .init(hex: "#eeedf1"),
  surfaceContainerHigh: .init(hex: "#e9e7eb"),
  surfaceContainerHighest: .init(hex: "#e3e2e6"),
  outline: .init(hex: "#74777f"),
  outlineVariant: .init(hex: "#c4c6cf"),
  scrim: .init(hex: "#000000"),
  shadow: .init(hex: "#000000")
)

let darkColors = ThemeColors(
  primary: .init(hex: "#a7c8ff"),
  onPrimary: .init(hex: "#003060"),
  primaryContainer: .init(hex: "#004788"),
  onPrimaryContainer: .init(hex: "#d5e3ff"),
  secondary: .init(hex: "#bdc7dc"),
  onSecondary: .init(hex: "#273141"),
  secondaryContainer: .init(hex: "#3d4758"),
  onSecondaryContainer: .init(hex: "#d9e3f8"),
  tertiary: .init(hex: "#dbbce2"),
  onTertiary: .init(hex: "#3e2845"),
  tertiaryContainer: .init(hex: "#553e5d"),
  onTertiaryContainer: .init(hex: "#f8d8fe"),
  background: .init(hex: "#1a1c1e"),
  onBackground: .init(hex: "#e3e2e6"),
  error: .init(hex: "#ffb4ab"),
  onError: .init(hex: "#690005"),
  errorContainer: .init(hex: "#93000a"),
  onErrorContainer: .init(hex: "#ffdad6"),
  inverseSurface: .init(hex: "#e3e2e6"),
  inverseOnSurface: .init(hex: "#2f3033"),
  inversePrimary: .init(hex: "#215fa7"),
  surface: .init(hex: "#121316"),
  onSurface: .init(hex: "#e3e2e6"),
  surfaceVariant: .init(hex: "#43474e"),
  onSurfaceVariant: .init(hex: "#c4c6cf"),
  surfaceDim: .init(hex: "#121316"),
  surfaceBright: .init(hex: "#38393c"),
  surfaceContainerLowest: .init(hex: "#0d0e11"),
  surfaceContainerLow: .init(hex: "#1a1c1e"),
  surfaceContainer: .init(hex: "#1e2023"),
  surfaceContainerHigh: .init(hex: "#292a2d"),
  surfaceContainerHighest: .init(hex: "#343538"),
  outline: .init(hex: "#8e9199"),
  outlineVariant: .init(hex: "#43474e"),
  scrim: .init(hex: "#000000"),
  shadow: .init(hex: "#000000")
)

// MARK: - Generated Theme

let lightTheme: Theme = .defaultLight.copy(colors: lightColors)

let darkTheme: Theme = .defaultDark.copy(colors: darkColors)

struct CustomThemeProvider<Content: View>: View {
  private let content: () -> Content
  
  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }

  var body: some View {
    ThemeProvider(light: lightTheme, dark: darkTheme) {
      content()
    }
  }
}