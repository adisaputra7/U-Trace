import Foundation
import Observation

@MainActor
@Observable
final class AppEnvironment {
    let api: InsforgeAPIClient
    let walletRepo: any WalletRepository
    let categoryRepo: any CategoryRepository
    let transactionRepo: any TransactionRepository
    let familyRepo: any FamilyRepository
    let auth: AuthService
    let session: SessionStore

    var currentFamily: FamilyModel?

    /// Incremented whenever transactions/wallets change, so listeners (Dashboard etc.) can reload.
    var dataVersion: Int = 0

    private var authObserver: NSObjectProtocol?

    func notifyDataChanged() {
        dataVersion &+= 1
    }

    init() {
        let api = InsforgeAPIClient()
        self.api = api

        let txCounter = TransactionCounter(api: api)
        let walletRepo = InsforgeWalletRepository(api: api, txCounter: txCounter)
        let categoryRepo = InsforgeCategoryRepository(api: api)
        let transactionRepo = InsforgeTransactionRepository(api: api, walletRepo: walletRepo)
        let familyRepo = InsforgeFamilyRepository(api: api)

        self.walletRepo = walletRepo
        self.categoryRepo = categoryRepo
        self.transactionRepo = transactionRepo
        self.familyRepo = familyRepo

        let auth = InsforgeAuthService(api: api)
        self.auth = auth
        let session = SessionStore(auth: auth)
        self.session = session

        api.refreshHandler = { [weak auth, weak session] in
            guard let auth, let session else { throw APIError.unauthenticated }
            let renewed = try await auth.refresh()
            session.session = renewed
        }

        authObserver = NotificationCenter.default.addObserver(
            forName: .didAuthenticate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.seedIfNeeded()
                await self?.loadFamily()
            }
        }
    }

    func bootstrap() async {
        await session.bootstrap()
        await loadFamily()
        await seedIfNeeded()
    }

    func loadFamily() async {
        guard let userId = session.session?.userId else { return }
        do {
            let family = try await familyRepo.myFamily(userId: userId)
            currentFamily = family
            api.currentFamilyId = family?.id
        } catch {
            print("[Bootstrap] Family load failed: \(error)")
        }
    }

    private func seedIfNeeded() async {
        guard session.isAuthenticated else { return }
        do {
            try await categoryRepo.seedSystemCategoriesIfNeeded()
        } catch {
            print("[Bootstrap] Failed to seed categories: \(error)")
        }
    }
}
