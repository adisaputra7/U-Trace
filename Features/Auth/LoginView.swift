import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: AuthViewModel
    var onSwitchToRegister: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome back")
                    .font(AppFont.display)
                    .foregroundStyle(Theme.Palette.bgDeep)
                Text("Sign in to keep tracking your finances.")
                    .font(AppFont.body)
                    .foregroundStyle(Theme.Palette.bgDeep.opacity(0.5))
            }

            VStack(spacing: Theme.Spacing.md) {
                AuthTextField(
                    title: "Email",
                    text: $viewModel.email,
                    icon: "envelope.fill",
                    keyboard: .emailAddress
                )
                AuthTextField(
                    title: "Password",
                    text: $viewModel.password,
                    icon: "lock.fill",
                    isSecure: true
                )
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(AppFont.captionMedium)
                    .foregroundStyle(Theme.Palette.danger)
                    .transition(.opacity)
            }

            Button {
                Task { await viewModel.login() }
            } label: {
                HStack {
                    if viewModel.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Sign In")
                    }
                }
            }
            .buttonStyle(AuthPrimaryButtonStyle())
            .disabled(viewModel.isSubmitting)

            HStack {
                Text("New here?")
                    .foregroundStyle(Theme.Palette.bgDeep.opacity(0.5))
                Button("Create an account") {
                    viewModel.reset()
                    onSwitchToRegister()
                }
                .foregroundStyle(Theme.Palette.bgDeep)
                .fontWeight(.semibold)
            }
            .font(AppFont.captionMedium)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .authCard()
        .padding(Theme.Spacing.xl)
    }
}
