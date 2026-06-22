import SwiftUI

struct AddTransactionSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: TransactionViewModel?
    @State private var amountText: String = ""
    @State private var type: TxType = .expense
    @State private var date: Date = .now
    @State private var note: String = ""
    @State private var selectedWallet: WalletModel?
    @State private var selectedCategory: CategoryModel?
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color(hex: "#F5F7FA").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    Text("Quick Add")
                        .font(AppFont.display)
                        .foregroundStyle(Theme.Palette.textPrimary)

                    typeSegment
                    amountField
                    walletPicker
                    categoryPicker
                    dateField
                    noteField

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppFont.captionMedium)
                            .foregroundStyle(Theme.Palette.danger)
                    }

                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView().tint(Theme.Palette.bgDeep)
                            } else {
                                Text("Save Transaction")
                            }
                        }
                    }
                    .buttonStyle(GlassPrimaryButtonStyle())
                    .disabled(isSaving)
                }
                .padding(Theme.Spacing.xl)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = TransactionViewModel(
                    transactionRepo: env.transactionRepo,
                    walletRepo: env.walletRepo,
                    categoryRepo: env.categoryRepo,
                    session: session
                )
            }
            Task {
                await viewModel?.bootstrap()
                selectedWallet = viewModel?.wallets.first
                selectedCategory = compatibleCategories.first
            }
        }
        .onChange(of: type) { _, _ in
            if let selectedCategory, !compatibleCategories.contains(where: { $0.id == selectedCategory.id }) {
                self.selectedCategory = compatibleCategories.first
            }
        }
    }

    // MARK: - Sub views

    private var typeSegment: some View {
        HStack(spacing: 8) {
            ForEach(TxType.allCases) { value in
                Button {
                    withAnimation(Motion.snappy) { type = value }
                } label: {
                    Label(value.displayName, systemImage: value == .income ? "arrow.down.left" : "arrow.up.right")
                        .font(AppFont.bodySemibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(type == value ? Theme.Palette.bgDeep : Theme.Palette.textPrimary)
                        .background {
                            if type == value {
                                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                    .fill(value == .income ? AnyShapeStyle(Theme.Palette.mintGradient) : AnyShapeStyle(Theme.Palette.pinkAmberGradient))
                            } else {
                                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                    .fill(Theme.Palette.glassFill)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                .strokeBorder(Theme.Palette.glassStroke, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(AppFont.overline)
                .tracking(1.0)
                .foregroundStyle(Theme.Palette.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Rp")
                    .font(AppFont.title)
                    .foregroundStyle(Theme.Palette.textSecondary)
                TextField("0", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(AppFont.displayLarge)
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .tint(Theme.Palette.accentMint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var walletPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Wallet")
                .font(AppFont.overline)
                .tracking(1.0)
                .foregroundStyle(Theme.Palette.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel?.wallets ?? []) { wallet in
                        Button {
                            selectedWallet = wallet
                        } label: {
                            HStack(spacing: 8) {
                                Circle().fill(Color(hex: wallet.colorHex)).frame(width: 12, height: 12)
                                Text(wallet.name)
                                    .font(AppFont.captionMedium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .foregroundStyle(selectedWallet?.id == wallet.id ? Theme.Palette.bgDeep : Theme.Palette.textPrimary)
                            .background {
                                Capsule().fill(selectedWallet?.id == wallet.id
                                               ? AnyShapeStyle(Theme.Palette.mintGradient)
                                               : AnyShapeStyle(Theme.Palette.glassFill))
                            }
                            .overlay(Capsule().strokeBorder(Theme.Palette.glassStroke, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)
    }

    private var compatibleCategories: [CategoryModel] {
        (viewModel?.categories ?? []).filter { $0.scope.matches(type) }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category")
                .font(AppFont.overline)
                .tracking(1.0)
                .foregroundStyle(Theme.Palette.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(compatibleCategories) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: category.iconName)
                                    .font(.system(size: 12, weight: .semibold))
                                Text(category.name)
                                    .font(AppFont.captionMedium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .foregroundStyle(selectedCategory?.id == category.id ? Theme.Palette.bgDeep : Theme.Palette.textPrimary)
                            .background {
                                Capsule().fill(selectedCategory?.id == category.id
                                               ? AnyShapeStyle(Color(hex: category.colorHex))
                                               : AnyShapeStyle(Theme.Palette.glassFill))
                            }
                            .overlay(Capsule().strokeBorder(Theme.Palette.glassStroke, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)
    }

    private var dateField: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundStyle(Theme.Palette.textSecondary)
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .tint(Theme.Palette.accentMint)
                .foregroundStyle(Theme.Palette.textPrimary)
        }
        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)
    }

    private var noteField: some View {
        GlassTextField(title: "Note (optional)", text: $note, icon: "text.alignleft", autocap: .sentences)
    }

    // MARK: - Save

    private func save() async {
        guard let amount = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")), amount > 0 else {
            errorMessage = "Please enter a valid amount."
            return
        }
        guard let wallet = selectedWallet else {
            errorMessage = "Please pick a wallet first."
            return
        }
        guard let category = selectedCategory else {
            errorMessage = "Please pick a category."
            return
        }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let draft = TransactionDraft(
            amount: amount,
            type: type,
            date: date,
            note: note.isEmpty ? nil : note,
            walletId: wallet.id,
            categoryId: category.id,
            createdBy: session.session?.userId
        )
        let success = await viewModel?.createTransaction(draft: draft) ?? false
        if success { dismiss() }
        else { errorMessage = viewModel?.errorMessage }
    }
}
