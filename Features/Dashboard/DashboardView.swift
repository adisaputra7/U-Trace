import SwiftUI

struct DashboardView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(SessionStore.self) private var session
    @State private var viewModel: DashboardViewModel?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.xl) {
                header
                balanceCard
                incomeExpenseRow
                trendCard
                recentList
                if let errorMessage = viewModel?.errorMessage {
                    Text(errorMessage)
                        .font(AppFont.captionMedium)
                        .foregroundStyle(Theme.Palette.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.md)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.top, Theme.Spacing.xl)
            .padding(.bottom, 120)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = DashboardViewModel(
                    walletRepo: env.walletRepo,
                    transactionRepo: env.transactionRepo,
                    session: session
                )
            }
            Task { await viewModel?.reload() }
        }
        .refreshable { await viewModel?.reload() }
        .onReceive(NotificationCenter.default.publisher(for: .transactionsDidChange)) { _ in
            Task { await viewModel?.reload() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .familyDidChange)) { _ in
            Task { await viewModel?.reload() }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hello,")
                    .font(AppFont.captionMedium)
                    .foregroundStyle(Theme.Palette.textSecondary)
                Text(session.session?.email.split(separator: "@").first.map(String.init) ?? "User")
                    .font(AppFont.title)
                    .foregroundStyle(Theme.Palette.textPrimary)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 42, height: 42)
                    .overlay(Circle().strokeBorder(Theme.Palette.glassStroke, lineWidth: 1))
                Image(systemName: "bell.fill")
                    .foregroundStyle(Theme.Palette.textPrimary)
            }
        }
    }

    // MARK: - Balance
    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TOTAL BALANCE")
                .font(AppFont.overline)
                .tracking(1.2)
                .foregroundStyle(Theme.Palette.textSecondary)
            Text(Formatter.currency(viewModel?.totalBalance ?? 0))
                .font(AppFont.displayLarge)
                .foregroundStyle(Theme.Palette.textPrimary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    // MARK: - Income/Expense Row
    private var incomeExpenseRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            metricCard(
                title: "INCOME",
                value: viewModel?.monthIncome ?? 0,
                icon: "arrow.down.left",
                color: Theme.Palette.accentMint
            )
            metricCard(
                title: "EXPENSE",
                value: viewModel?.monthExpense ?? 0,
                icon: "arrow.up.right",
                color: Theme.Palette.accentPink
            )
        }
    }

    private func metricCard(title: String, value: Decimal, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(color)
                }
                Text(title)
                    .font(AppFont.overline)
                    .tracking(1.0)
                    .foregroundStyle(Theme.Palette.textSecondary)
                Spacer()
            }
            Text(Formatter.currency(value))
                .font(AppFont.titleMedium)
                .foregroundStyle(Theme.Palette.textPrimary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)
    }

    // MARK: - Trend
    private var trendCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Spending Trend")
                    .font(AppFont.titleMedium)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(Theme.Palette.accentMint).frame(width: 8, height: 8)
                    Text("Income").font(AppFont.caption).foregroundStyle(Theme.Palette.textSecondary)
                    Circle().fill(Theme.Palette.accentPink).frame(width: 8, height: 8).padding(.leading, 8)
                    Text("Expense").font(AppFont.caption).foregroundStyle(Theme.Palette.textSecondary)
                }
            }
            SpendingTrendChart(monthlyTotals: viewModel?.monthlyTotals ?? [])
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    // MARK: - Recent
    private var recentList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Recent Transactions")
                .font(AppFont.titleMedium)
                .foregroundStyle(Theme.Palette.textPrimary)

            VStack(spacing: 10) {
                let items = viewModel?.recentTransactions ?? []
                if items.isEmpty {
                    EmptyHint(title: "No transactions yet", subtitle: "Tap + to add your first entry")
                        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)
                } else {
                    ForEach(items) { tx in
                        TransactionRow(transaction: tx)
                            .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.md)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyHint: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Theme.Palette.accentMint)
            Text(title)
                .font(AppFont.bodySemibold)
                .foregroundStyle(Theme.Palette.textPrimary)
            Text(subtitle)
                .font(AppFont.caption)
                .foregroundStyle(Theme.Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

enum Formatter {
    static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "IDR"
        f.currencySymbol = "Rp "
        f.maximumFractionDigits = 0
        return f
    }()

    static func currency(_ value: Decimal) -> String {
        currencyFormatter.string(from: NSDecimalNumber(decimal: value)) ?? "Rp 0"
    }

    static let dateRelative: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
}
