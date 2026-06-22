import SwiftUI

struct GlassBackground: View {
    @State private var animateBlobs = false

    var body: some View {
        ZStack {
            Theme.Palette.primaryGradient
                .ignoresSafeArea()

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                Canvas { _, _ in } symbols: { } // canvas placeholder; keeps timeline updating

                ZStack {
                    Circle()
                        .fill(Theme.Palette.accentPink.opacity(0.55))
                        .frame(width: 320, height: 320)
                        .blur(radius: 120)
                        .offset(
                            x: CGFloat(sin(t * 0.25)) * 80 - 120,
                            y: CGFloat(cos(t * 0.20)) * 100 - 220
                        )

                    Circle()
                        .fill(Theme.Palette.accentSky.opacity(0.45))
                        .frame(width: 360, height: 360)
                        .blur(radius: 130)
                        .offset(
                            x: CGFloat(cos(t * 0.18)) * 100 + 140,
                            y: CGFloat(sin(t * 0.22)) * 90 + 40
                        )

                    Circle()
                        .fill(Theme.Palette.accentMint.opacity(0.40))
                        .frame(width: 280, height: 280)
                        .blur(radius: 110)
                        .offset(
                            x: CGFloat(sin(t * 0.16)) * 70 + 60,
                            y: CGFloat(cos(t * 0.24)) * 110 + 260
                        )
                }
            }
            .ignoresSafeArea()

            Color.black.opacity(0.18).ignoresSafeArea()
        }
    }
}

#Preview {
    GlassBackground()
        .preferredColorScheme(.dark)
}
