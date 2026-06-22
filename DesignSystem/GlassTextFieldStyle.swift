import SwiftUI

struct GlassTextField: View {
    let title: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var autocap: TextInputAutocapitalization = .never

    private static let textColor        = Theme.Palette.textPrimary
    private static let placeholderColor = Theme.Palette.textTertiary

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
                .tint(Theme.Palette.accentMint)
            } else {
                TextField(
                    "",
                    text: $text,
                    prompt: Text(title).foregroundColor(Self.placeholderColor)
                )
                .font(AppFont.body)
                .foregroundColor(Self.textColor)
                .tint(Theme.Palette.accentMint)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocap)
                .autocorrectionDisabled()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Palette.glassFill)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .strokeBorder(Theme.Palette.glassStroke, lineWidth: 1)
        }
    }
}
