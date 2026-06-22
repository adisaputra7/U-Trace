import SwiftUI

struct QuickAddFAB: View {
    var action: () -> Void
    @State private var pressed: Bool = false

    var body: some View {
        Button {
            withAnimation(Motion.bouncy) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(Motion.bouncy) { pressed = false }
            }
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(Theme.Palette.mintGradient)
                    .frame(width: 60, height: 60)
                    .shadow(color: Theme.Palette.accentMint.opacity(0.55), radius: 22, y: 10)

                Circle()
                    .strokeBorder(.white.opacity(0.35), lineWidth: 1)
                    .frame(width: 60, height: 60)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.Palette.bgDeep)
                    .scaleEffect(pressed ? 0.85 : 1.0)
                    .animation(Motion.bouncy, value: pressed)
            }
        }
        .buttonStyle(.plain)
    }
}
