import SwiftUI

// MARK: - AuthTextField
// Clean white-background text field for the auth screens.

struct AuthTextField: View {
    let title: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default

    private static let textColor        = Color(hex: "#0B0F2A")
    private static let placeholderColor = Color(hex: "#9DA3B4")
    private static let bgColor          = Color(hex: "#F2F3F7")
    private static let borderColor      = Color(hex: "#D1D3DC")

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Self.placeholderColor)
                    .frame(width: 22)
            }

            if isSecure {
                SecureField(
                    "",
                    text: $text,
                    prompt: Text(title).foregroundColor(Self.placeholderColor)
                )
                .font(AppFont.body)
                .foregroundColor(Self.textColor)
                .tint(Self.textColor)
            } else {
                TextField(
                    "",
                    text: $text,
                    prompt: Text(title).foregroundColor(Self.placeholderColor)
                )
                .font(AppFont.body)
                .foregroundColor(Self.textColor)
                .tint(Self.textColor)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Self.bgColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .strokeBorder(Self.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - AuthPrimaryButtonStyle
// Solid dark button used on the white auth screen.

struct AuthPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.bodySemibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(Theme.Palette.bgDeep)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(Motion.snappy, value: configuration.isPressed)
    }
}

// MARK: - authCard modifier
// Card style for auth forms on a white background.

private struct AuthCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .strokeBorder(Color(uiColor: .systemGray5), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 6)
    }
}

extension View {
    func authCard() -> some View {
        modifier(AuthCardModifier())
    }
}
