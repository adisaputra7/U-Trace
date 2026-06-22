import SwiftUI

struct TransactionFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    let wallets: [WalletModel]
    let categories: [CategoryModel]
    @Binding var draft: TxFilter
    var onApply: (TxFilter) -> Void

    @State private var useDateRange: Bool = false
    @State private var startDate: Date = .now.addingTimeInterval(-30 * 24 * 3600)
    @State private var endDate: Date = .now
    @State private var selectedType: TxType?
    @State private var selectedWalletId: UUID?
    @State private var selectedCategoryId: UUID?

    var body: some View {
        ZStack {
            Color(hex: "#F5F7FA").ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    Text("Filter")
                        .font(AppFont.display)
                        .foregroundStyle(Theme.Palette.textPrimary)

                    typeSection
                    walletSection
                    categorySection
                    dateSection

                    HStack(spacing: Theme.Spacing.md) {
                        Button("Reset") {
                            reset()
                            onApply(.none)
                            dismiss()
                        }
                        .buttonStyle(GlassSecondaryButtonStyle())

                        Button("Apply") {
                            apply()
                        }
                        .buttonStyle(GlassPrimaryButtonStyle())
                    }
                }
                .padding(Theme.Spacing.xl)
            }
        }
        .onAppear { hydrate() }
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Type")
                .font(AppFont.overline)
                .tracking(1.0)
                .foregroundStyle(Theme.Palette.textSecondary)
            HStack {
                pill("All", isActive: selectedType == nil) { selectedType = nil }
                pill("Income", isActive: selectedType == .income) { selectedType = .income }
                pill("Expense", isActive: selectedType == .expense) { selectedType = .expense }
            }
        }
        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)
    }

    private var walletSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Wallet")
                .font(AppFont.overline)
                .tracking(1.0)
                .foregroundStyle(Theme.Palette.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    pill("All", isActive: selectedWalletId == nil) { selectedWalletId = nil }
                    ForEach(wallets) { wallet in
                        pill(wallet.name, isActive: selectedWalletId == wallet.id) {
                            selectedWalletId = wallet.id
                        }
                    }
                }
            }
        }
        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category")
                .font(AppFont.overline)
                .tracking(1.0)
                .foregroundStyle(Theme.Palette.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    pill("All", isActive: selectedCategoryId == nil) { selectedCategoryId = nil }
                    ForEach(categories) { category in
                        pill(category.name, isActive: selectedCategoryId == category.id) {
                            selectedCategoryId = category.id
                        }
                    }
                }
            }
        }
        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $useDateRange) {
                Text("Date range")
                    .font(AppFont.bodySemibold)
                    .foregroundStyle(Theme.Palette.textPrimary)
            }
            .tint(Theme.Palette.accentMint)

            if useDateRange {
                DatePicker("From", selection: $startDate, displayedComponents: .date)
                    .tint(Theme.Palette.accentMint)
                    .foregroundStyle(Theme.Palette.textPrimary)
                DatePicker("To", selection: $endDate, displayedComponents: .date)
                    .tint(Theme.Palette.accentMint)
                    .foregroundStyle(Theme.Palette.textPrimary)
            }
        }
        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)
    }

    private func pill(_ text: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(text, action: action)
            .buttonStyle(GlassPillButtonStyle(isActive: isActive))
    }

    private func hydrate() {
        selectedType = draft.type
        selectedWalletId = draft.walletId
        selectedCategoryId = draft.categoryId
        if let s = draft.startDate, let e = draft.endDate {
            useDateRange = true
            startDate = s
            endDate = e
        }
    }

    private func reset() {
        selectedType = nil
        selectedWalletId = nil
        selectedCategoryId = nil
        useDateRange = false
    }

    private func apply() {
        var newFilter = TxFilter()
        newFilter.type = selectedType
        newFilter.walletId = selectedWalletId
        newFilter.categoryId = selectedCategoryId
        if useDateRange {
            newFilter.startDate = startDate
            newFilter.endDate = endDate
        }
        draft = newFilter
        onApply(newFilter)
        dismiss()
    }
}
