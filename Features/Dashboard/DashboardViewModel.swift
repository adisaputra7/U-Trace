import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    var totalBalance: Decimal = 0
    var monthIncome: Decimal = 0
    var monthExpense: Decimal = 0
    var monthlyTotals: [MonthlyTotal] = []
    var recentTransactions: [TransactionModel] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let walletRepo: WalletRepository
    private let transactionRepo: TransactionRepository
    private let session: SessionStore

    init(walletRepo: WalletRepository, transactionRepo: TransactionRepository, session: SessionStore) {
        self.walletRepo = walletRepo
        self.transactionRepo = transactionRepo
        self.session = session
    }

    func reload() async {
        guard let userId = session.session?.userId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let wallets = try await walletRepo.list(ownerId: userId)
            totalBalance = wallets.reduce(0) { $0 + $1.balance }

            let now = Date()
            let calendar = Calendar.current
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? now

            let totals = try await transactionRepo.totalsForPeriod(ownerId: userId, start: start, end: end)
            monthIncome = totals.income
            monthExpense = totals.expense

            let year = calendar.component(.year, from: now)
            monthlyTotals = try await transactionRepo.monthlyTotals(ownerId: userId, year: year)

            recentTransactions = try await transactionRepo.list(
                ownerId: userId,
                filter: .none,
                page: PageRequest(offset: 0, limit: 5)
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            print("[Dashboard] Reload failed: \(error)")
        }
    }
}
