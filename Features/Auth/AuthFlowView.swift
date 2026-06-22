import SwiftUI

struct AuthFlowView: View {
    @Environment(SessionStore.self) private var session
    @State private var mode: Mode = .login
    @State private var viewModel: AuthViewModel?

    enum Mode { case login, register }

    var body: some View {
        ZStack {
            // Solid white background for auth screens.
            Color.white.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.xxxl) {
                    BrandHeader()
                        .padding(.top, Theme.Spacing.xxxl)

                    if let viewModel {
                        Group {
                            if mode == .login {
                                LoginView(viewModel: viewModel) {
                                    withAnimation(Motion.snappy) { mode = .register }
                                }
                                .transition(.move(edge: .leading).combined(with: .opacity))
                            } else {
                                RegisterView(viewModel: viewModel) {
                                    withAnimation(Motion.snappy) { mode = .login }
                                }
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .onAppear {
            if viewModel == nil { viewModel = AuthViewModel(session: session) }
        }
    }
}

private struct BrandHeader: View {
    var body: some View {
        VStack(spacing: 14) {
            // App icon — uses the actual AppIcon asset from Assets.xcassets.
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.Palette.mintGradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: Theme.Palette.accentMint.opacity(0.35), radius: 20, y: 8)

                // Try to load the real AppIcon; fall back to a money-stack glyph.
                if let uiImage = UIImage(named: "AppIcon") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                } else {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            Text("U Trace")
                .font(AppFont.display)
                .foregroundStyle(Theme.Palette.bgDeep)

            Text("Track money, beautifully.")
                .font(AppFont.captionMedium)
                .foregroundStyle(Theme.Palette.bgDeep.opacity(0.5))
        }
    }
}
