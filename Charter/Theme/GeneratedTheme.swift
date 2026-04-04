import SwiftUI
import SwiftThemeKit

// MARK: - Generated ThemeColors

let lightColors = ThemeColors(
  primary: .init("#215fa7"),
  onPrimary: .init("#ffffff"),
  primaryContainer: .init("#d5e3ff"),
  onPrimaryContainer: .init("#004788"),
  secondary: .init("#555f71"),
  onSecondary: .init("#ffffff"),
  secondaryContainer: .init("#d9e3f8"),
  onSecondaryContainer: .init("#3d4758"),
  tertiary: .init("#6e5676"),
  onTertiary: .init("#ffffff"),
  tertiaryContainer: .init("#f8d8fe"),
  onTertiaryContainer: .init("#553e5d"),
  background: .init("#fdfbff"),
  onBackground: .init("#1a1c1e"),
  error: .init("#ba1a1a"),
  onError: .init("#ffffff"),
  errorContainer: .init("#ffdad6"),
  onErrorContainer: .init("#93000a"),
  inverseSurface: .init("#2f3033"),
  inverseOnSurface: .init("#f1f0f4"),
  inversePrimary: .init("#a7c8ff"),
  surface: .init("#faf9fd"),
  onSurface: .init("#1a1c1e"),
  surfaceVariant: .init("#e0e2ec"),
  onSurfaceVariant: .init("#43474e"),
  surfaceDim: .init("#dad9dd"),
  surfaceBright: .init("#faf9fd"),
  surfaceContainerLowest: .init("#ffffff"),
  surfaceContainerLow: .init("#f4f3f7"),
  surfaceContainer: .init("#eeedf1"),
  surfaceContainerHigh: .init("#e9e7eb"),
  surfaceContainerHighest: .init("#e3e2e6"),
  outline: .init("#74777f"),
  outlineVariant: .init("#c4c6cf"),
  scrim: .init("#000000"),
  shadow: .init("#000000")
)

let darkColors = ThemeColors(
  primary: .init("#a7c8ff"),
  onPrimary: .init("#003060"),
  primaryContainer: .init("#004788"),
  onPrimaryContainer: .init("#d5e3ff"),
  secondary: .init("#bdc7dc"),
  onSecondary: .init("#273141"),
  secondaryContainer: .init("#3d4758"),
  onSecondaryContainer: .init("#d9e3f8"),
  tertiary: .init("#dbbce2"),
  onTertiary: .init("#3e2845"),
  tertiaryContainer: .init("#553e5d"),
  onTertiaryContainer: .init("#f8d8fe"),
  background: .init("#1a1c1e"),
  onBackground: .init("#e3e2e6"),
  error: .init("#ffb4ab"),
  onError: .init("#690005"),
  errorContainer: .init("#93000a"),
  onErrorContainer: .init("#ffdad6"),
  inverseSurface: .init("#e3e2e6"),
  inverseOnSurface: .init("#2f3033"),
  inversePrimary: .init("#215fa7"),
  surface: .init("#121316"),
  onSurface: .init("#e3e2e6"),
  surfaceVariant: .init("#43474e"),
  onSurfaceVariant: .init("#c4c6cf"),
  surfaceDim: .init("#121316"),
  surfaceBright: .init("#38393c"),
  surfaceContainerLowest: .init("#0d0e11"),
  surfaceContainerLow: .init("#1a1c1e"),
  surfaceContainer: .init("#1e2023"),
  surfaceContainerHigh: .init("#292a2d"),
  surfaceContainerHighest: .init("#343538"),
  outline: .init("#8e9199"),
  outlineVariant: .init("#43474e"),
  scrim: .init("#000000"),
  shadow: .init("#000000")
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