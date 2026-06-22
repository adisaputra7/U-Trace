import SwiftUI

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = Theme.Radius.lg
    var padding: CGFloat = Theme.Spacing.xl
    var strokeColor: Color = Theme.Palette.glassStroke
    var fillTint: Color = Theme.Palette.glassFill

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func glassCard(
        cornerRadius: CGFloat = Theme.Radius.lg,
        padding: CGFloat = Theme.Spacing.xl,
        strokeColor: Color = Theme.Palette.glassStroke,
        fillTint: Color = Theme.Palette.glassFill
    ) -> some View {
        modifier(GlassCardModifier(
            cornerRadius: cornerRadius,
            padding: padding,
            strokeColor: strokeColor,
            fillTint: fillTint
        ))
    }
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = Theme.Radius.lg
    var padding: CGFloat = Theme.Spacing.xl
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .glassCard(cornerRadius: cornerRadius, padding: padding)
    }
}

#Preview {
    ZStack {
        GlassBackground()
        VStack(spacing: Theme.Spacing.lg) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Balance")
                        .font(AppFont.caption)
                        .foregroundStyle(Theme.Palette.textSecondary)
                    Text("Rp 20.280.500")
                        .font(AppFont.displayLarge)
                        .foregroundStyle(Theme.Palette.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GlassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg) {
                HStack {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundStyle(Theme.Palette.accentMint)
                    Text("Income +Rp 2.119.000")
                        .font(AppFont.bodyMedium)
                        .foregroundStyle(Theme.Palette.textPrimary)
                    Spacer()
                }
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
