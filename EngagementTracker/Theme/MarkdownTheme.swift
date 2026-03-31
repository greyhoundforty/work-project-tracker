import SwiftUI
import MarkdownUI

extension Theme {
    static let engagementTracker = Theme()
        .text {
            ForegroundColor(.themeFg)
            FontSize(13)
        }
        .link {
            ForegroundColor(.themeBlue)
        }
        .strong {
            FontWeight(.semibold)
        }
        .emphasis {
            FontStyle(.italic)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.9))
            ForegroundColor(.themeAqua)
            BackgroundColor(.themeBg2)
        }
        .codeBlock { configuration in
            configuration.label
                .markdownTextStyle {
                    FontFamilyVariant(.monospaced)
                    FontSize(.em(0.9))
                    ForegroundColor(.themeAqua)
                }
                .padding(12)
                .background(Color.themeBg2)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .markdownMargin(top: 4, bottom: 4)
        }
        .blockquote { configuration in
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.themeYellow)
                    .frame(width: 3)
                configuration.label
                    .markdownTextStyle {
                        FontStyle(.italic)
                        ForegroundColor(.themeFgDim)
                    }
                    .padding(.leading, 10)
            }
            .markdownMargin(top: 4, bottom: 4)
        }
        .heading1 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(.em(1.6))
                    ForegroundColor(.themeFg)
                }
                .markdownMargin(top: 12, bottom: 4)
        }
        .heading2 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.3))
                    ForegroundColor(.themeFg)
                }
                .markdownMargin(top: 10, bottom: 4)
        }
        .heading3 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.1))
                    ForegroundColor(.themeFg)
                }
                .markdownMargin(top: 8, bottom: 4)
        }
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: .em(0.15))
        }
        .paragraph { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.2))
                .markdownMargin(top: 0, bottom: 4)
        }
}
