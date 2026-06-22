import SwiftUI

struct GlassPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.bodySemibold)
            .foregroundStyle(Theme.Palette.bgDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(Theme.Palette.mintGradient)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: Theme.Palette.accentMint.opacity(0.35), radius: 18, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(Motion.snappy, value: configuration.isPressed)
    }
}

struct GlassSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.bodySemibold)
            .foregroundStyle(Theme.Palette.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(Color.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(Theme.Palette.glassStrokeStrong, lineWidth: 1.5)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(Motion.snappy, value: configuration.isPressed)
    }
}

struct GlassPillButtonStyle: ButtonStyle {
    var isActive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.captionMedium)
            .foregroundStyle(isActive ? Theme.Palette.bgDeep : Theme.Palette.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(isActive ? AnyShapeStyle(Theme.Palette.mintGradient) : AnyShapeStyle(Theme.Palette.glassFill))
            }
            .overlay {
                Capsule().strokeBorder(Theme.Palette.glassStroke, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(Motion.snappy, value: configuration.isPressed)
    }
}
