import SwiftUI

struct WalletListView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(SessionStore.self) private var session
    @State private var viewModel: WalletViewModel?
    @State private var showEditor: Bool = false
    @State private var editing: WalletModel?
    @State private var showCategories: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.xl) {
                header

                if let viewModel {
                    if viewModel.wallets.isEmpty {
                        EmptyHint(title: "No wallets yet", subtitle: "Tap + to create your first wallet")
                            .glassCard()
                    } else {
                        VStack(spacing: Theme.Spacing.md) {
                            ForEach(viewModel.wallets) { wallet in
                                WalletCard(wallet: wallet) {
                                    editing = wallet
                                    showEditor = true
                                } onDelete: {
                                    Task { await viewModel.delete(id: wallet.id) }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.top, Theme.Spacing.xl)
            .padding(.bottom, 120)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = WalletViewModel(walletRepo: env.walletRepo, session: session)
            }
            Task { await viewModel?.reload() }
        }
        .sheet(isPresented: $showEditor, onDismiss: {
            editing = nil
            Task { await viewModel?.reload() }
        }) {
            if let viewModel {
                WalletEditorSheet(viewModel: viewModel, existing: editing)
            }
        }
        .sheet(isPresented: $showCategories) {
            CategoryListView()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Wallets")
                    .font(AppFont.display)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text("Manage your accounts")
                    .font(AppFont.captionMedium)
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            Spacer()
            Button {
                showCategories = true
            } label: {
                Image(systemName: "tag.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .padding(10)
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay(Circle().strokeBorder(Theme.Palette.glassStroke, lineWidth: 1))
            }
            Button {
                editing = nil
                showEditor = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.Palette.bgDeep)
                    .padding(10)
                    .background(Circle().fill(Theme.Palette.mintGradient))
            }
        }
    }
}

struct WalletCard: View {
    let wallet: WalletModel
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack {
                Circle()
                    .fill(Color(hex: wallet.colorHex))
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "creditcard.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Palette.bgDeep))
                VStack(alignment: .leading, spacing: 2) {
                    Text(wallet.name)
                        .font(AppFont.titleMedium)
                        .foregroundStyle(Theme.Palette.textPrimary)
                    Text("\(wallet.transactionCount) transactions")
                        .font(AppFont.caption)
                        .foregroundStyle(Theme.Palette.textSecondary)
                }
                Spacer()
                Menu {
                    Button("Edit", systemImage: "pencil", action: onEdit)
                    Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Theme.Palette.textSecondary)
                        .padding(8)
                }
            }

            Text(Formatter.currency(wallet.balance))
                .font(AppFont.title)
                .foregroundStyle(Theme.Palette.textPrimary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.xl)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: wallet.colorHex).opacity(0.25), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .strokeBorder(Theme.Palette.glassStroke, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.07), radius: 12, y: 4)
    }
}
