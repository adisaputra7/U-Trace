import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        ZStack {
            Color(hex: "#F5F7FA").ignoresSafeArea()

            if session.isLoading {
                ProgressView()
                    .tint(Theme.Palette.textPrimary)
                    .transition(.opacity)
            } else if session.session == nil {
                AuthFlowView()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                MainTabView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(Motion.gentle, value: session.isLoading)
        .animation(Motion.gentle, value: session.session)
    }
}
