import SwiftUI

struct TransactionHistoryView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(SessionStore.self) private var session
    @State private var viewModel: TransactionViewModel?
    @State private var showFilter: Bool = false
    @State private var filterDraft: TxFilter = .none
    @State private var expandedId: UUID?

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: Theme.Spacing.lg) {
                header

                if let viewModel {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(AppFont.captionMedium)
                            .foregroundStyle(Theme.Palette.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.md)
                    }
                    if viewModel.isLoading && viewModel.transactions.isEmpty {
                        ProgressView()
                            .tint(Theme.Palette.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, Theme.Spacing.xxxl)
                    } else if viewModel.transactions.isEmpty {
                        EmptyHint(title: "No transactions", subtitle: "Try adjusting filters or add a new entry")
                            .glassCard()
                    } else {
                        ForEach(Array(viewModel.transactions.enumerated()), id: \.element.id) { index, tx in
                            TransactionRow(
                                transaction: tx,
                                isExpanded: expandedId == tx.id,
                                onTap: {
                                    withAnimation(Motion.gentle) {
                                        expandedId = expandedId == tx.id ? nil : tx.id
                                    }
                                }
                            )
                            .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.md)
                            .contextMenu {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    Task { await viewModel.delete(id: tx.id) }
                                }
                            }
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                                .onAppear {
                                    if index >= viewModel.transactions.count - 3 {
                                        Task { await viewModel.loadMore() }
                                    }
                                }
                        }

                        if viewModel.isLoadingMore {
                            ProgressView()
                                .tint(Theme.Palette.textPrimary)
                                .padding(.top, Theme.Spacing.md)
                        }
                    }
                }
            }
            .animation(Motion.gentle, value: viewModel?.transactions.map(\.id) ?? [])
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.top, Theme.Spacing.xl)
            .padding(.bottom, 120)
        }
        .refreshable { await viewModel?.reload() }
        .onReceive(NotificationCenter.default.publisher(for: .familyDidChange)) { _ in
            Task { await viewModel?.reload() }
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
            Task { await viewModel?.bootstrap() }
        }
        .sheet(isPresented: $showFilter) {
            if let viewModel {
                TransactionFilterSheet(
                    wallets: viewModel.wallets,
                    categories: viewModel.categories,
                    draft: $filterDraft
                ) { filter in
                    Task { await viewModel.applyFilter(filter) }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("History")
                    .font(AppFont.display)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text("All transactions")
                    .font(AppFont.captionMedium)
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            Spacer()
            Button {
                showFilter = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .padding(8)
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay(Circle().strokeBorder(Theme.Palette.glassStroke, lineWidth: 1))
            }
        }
    }
}
