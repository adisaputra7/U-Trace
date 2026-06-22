import SwiftUI

enum AppFont {
    static let displayLarge = Font.system(size: 40, weight: .heavy, design: .rounded)
    static let display      = Font.system(size: 32, weight: .bold, design: .rounded)
    static let title        = Font.system(size: 22, weight: .bold, design: .rounded)
    static let titleMedium  = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let body         = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium   = Font.system(size: 16, weight: .medium, design: .default)
    static let bodySemibold = Font.system(size: 16, weight: .semibold, design: .default)
    static let caption      = Font.system(size: 13, weight: .regular, design: .default)
    static let captionMedium = Font.system(size: 13, weight: .medium, design: .default)
    static let overline     = Font.system(size: 11, weight: .bold, design: .rounded)
    static let monoLarge    = Font.system(size: 34, weight: .heavy, design: .monospaced)
    static let monoMedium   = Font.system(size: 17, weight: .semibold, design: .monospaced)
}
