import Foundation
import Observation

@MainActor
@Observable
final class TransactionViewModel {
    var transactions: [TransactionModel] = []
    var wallets: [WalletModel] = []
    var categories: [CategoryModel] = []
    var filter: TxFilter = .none
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var canLoadMore: Bool = true
    var errorMessage: String?

    private let pageSize = 20
    private var offset = 0

    private let transactionRepo: TransactionRepository
    private let walletRepo: WalletRepository
    private let categoryRepo: CategoryRepository
    private let session: SessionStore

    init(
        transactionRepo: TransactionRepository,
        walletRepo: WalletRepository,
        categoryRepo: CategoryRepository,
        session: SessionStore
    ) {
        self.transactionRepo = transactionRepo
        self.walletRepo = walletRepo
        self.categoryRepo = categoryRepo
        self.session = session
    }

    func bootstrap() async {
        guard let userId = session.session?.userId else { return }
        do {
            wallets = try await walletRepo.list(ownerId: userId)
            categories = try await categoryRepo.list(ownerId: userId, scope: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
        await reload()
    }

    func reload() async {
        guard let userId = session.session?.userId else { return }
        isLoading = true
        offset = 0
        canLoadMore = true
        defer { isLoading = false }
        do {
            let page = try await transactionRepo.list(
                ownerId: userId,
                filter: filter,
                page: PageRequest(offset: 0, limit: pageSize)
            )
            transactions = page
            offset = page.count
            canLoadMore = page.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMore() async {
        guard let userId = session.session?.userId, canLoadMore, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await transactionRepo.list(
                ownerId: userId,
                filter: filter,
                page: PageRequest(offset: offset, limit: pageSize)
            )
            transactions.append(contentsOf: page)
            offset += page.count
            if page.count < pageSize { canLoadMore = false }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: UUID) async {
        do {
            try await transactionRepo.delete(id: id)
            await reload()
            NotificationCenter.default.post(name: .transactionsDidChange, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createTransaction(draft: TransactionDraft) async -> Bool {
        guard let userId = session.session?.userId else { return false }
        do {
            _ = try await transactionRepo.create(draft, ownerId: userId)
            await reload()
            NotificationCenter.default.post(name: .transactionsDidChange, object: nil)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func applyFilter(_ newFilter: TxFilter) async {
        filter = newFilter
        await reload()
    }
}

extension Notification.Name {
    static let transactionsDidChange = Notification.Name("transactionsDidChange")
}
