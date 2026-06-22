import SwiftUI

struct WalletEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: WalletViewModel
    var existing: WalletModel?

    @State private var name: String = ""
    @State private var balance: String = "0"
    @State private var colorHex: String = "#7CFFCB"

    private let palette = ["#7CFFCB", "#FF7CCB", "#FFD37C", "#7CD8FF", "#A0A0FF", "#FF6B7A"]

    var body: some View {
        ZStack {
            Color(hex: "#F5F7FA").ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    Text(existing == nil ? "New Wallet" : "Edit Wallet")
                        .font(AppFont.display)
                        .foregroundStyle(Theme.Palette.textPrimary)

                    GlassTextField(title: "Wallet name", text: $name, icon: "creditcard.fill", autocap: .words)

                    if existing == nil {
                        GlassTextField(title: "Initial balance", text: $balance, icon: "dollarsign", keyboard: .decimalPad)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Card Color")
                            .font(AppFont.overline)
                            .foregroundStyle(Theme.Palette.textSecondary)
                            .tracking(1.0)

                        HStack(spacing: 12) {
                            ForEach(palette, id: \.self) { hex in
                                Button {
                                    colorHex = hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 38, height: 38)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(colorHex == hex ? Color.white : Color(hex: "#E2E8F0"), lineWidth: 2)
                                        )
                                        .scaleEffect(colorHex == hex ? 1.1 : 1.0)
                                        .animation(Motion.snappy, value: colorHex)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(AppFont.captionMedium)
                            .foregroundStyle(Theme.Palette.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Spacer(minLength: Theme.Spacing.xxxl)

                    Button {
                        Task { await save() }
                    } label: {
                        Text(existing == nil ? "Create Wallet" : "Save Changes")
                    }
                    .buttonStyle(GlassPrimaryButtonStyle())
                }
                .padding(Theme.Spacing.xl)
            }
        }
        .onAppear {
            if let existing {
                name = existing.name
                colorHex = existing.colorHex
                balance = "\(existing.balance)"
            }
        }
    }

    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let success: Bool
        if let existing {
            success = await viewModel.update(id: existing.id, name: trimmedName, colorHex: colorHex)
        } else {
            let amount = Decimal(string: balance.replacingOccurrences(of: ",", with: ".")) ?? 0
            success = await viewModel.create(name: trimmedName, balance: amount, colorHex: colorHex)
        }
        if success { dismiss() }
    }
}
