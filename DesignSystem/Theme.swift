import SwiftUI

enum Theme {
    enum Palette {
        static let bgDeep      = Color(hex: "#0B0F2A")
        static let bgViolet    = Color(hex: "#1A0B3D")
        static let bgTeal      = Color(hex: "#0B2A2A")
        static let accentMint  = Color(hex: "#0ABDA0")
        static let accentPink  = Color(hex: "#E91E93")
        static let accentAmber = Color(hex: "#F59E0B")
        static let accentSky   = Color(hex: "#38BDF8")
        static let danger      = Color(hex: "#EF4444")
        static let success     = Color(hex: "#10B981")

        static let textPrimary   = Color(hex: "#0B0F2A")
        static let textSecondary = Color(hex: "#64748B")
        static let textTertiary  = Color(hex: "#94A3B8")

        static let glassFill        = Color(hex: "#F1F5F9")
        static let glassFillSoft    = Color(hex: "#F8FAFC")
        static let glassStroke      = Color(hex: "#E2E8F0")
        static let glassStrokeStrong = Color(hex: "#CBD5E1")

        static var primaryGradient: LinearGradient {
            LinearGradient(
                colors: [bgDeep, bgViolet, bgTeal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var mintGradient: LinearGradient {
            LinearGradient(
                colors: [accentMint, accentSky],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var pinkAmberGradient: LinearGradient {
            LinearGradient(
                colors: [accentPink, accentAmber],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 18
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let pill: CGFloat = 999
    }
}

extension Color {
    static let glassFill   = Theme.Palette.glassFill
    static let glassStroke = Theme.Palette.glassStroke
}
