import SwiftUI

struct RegisterView: View {
    @Bindable var viewModel: AuthViewModel
    var onSwitchToLogin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Create account")
                    .font(AppFont.display)
                    .foregroundStyle(Theme.Palette.bgDeep)
                Text("Start your U Trace journey.")
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
                    title: "Password (min 6 chars)",
                    text: $viewModel.password,
                    icon: "lock.fill",
                    isSecure: true
                )
                AuthTextField(
                    title: "Confirm Password",
                    text: $viewModel.confirmPassword,
                    icon: "lock.rotation",
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
                Task { await viewModel.register() }
            } label: {
                HStack {
                    if viewModel.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Create Account")
                    }
                }
            }
            .buttonStyle(AuthPrimaryButtonStyle())
            .disabled(viewModel.isSubmitting)

            HStack {
                Text("Already have an account?")
                    .foregroundStyle(Theme.Palette.bgDeep.opacity(0.5))
                Button("Sign in") {
                    viewModel.reset()
                    onSwitchToLogin()
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
