import Foundation
import Observation

@MainActor
@Observable
final class WalletViewModel {
    var wallets: [WalletModel] = []
    var errorMessage: String?

    private let walletRepo: WalletRepository
    private let session: SessionStore

    init(walletRepo: WalletRepository, session: SessionStore) {
        self.walletRepo = walletRepo
        self.session = session
    }

    func reload() async {
        guard let userId = session.session?.userId else { return }
        do {
            wallets = try await walletRepo.list(ownerId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func create(name: String, balance: Decimal, colorHex: String) async -> Bool {
        guard let userId = session.session?.userId else {
            errorMessage = "Not signed in."
            return false
        }
        do {
            _ = try await walletRepo.create(name: name, balance: balance, colorHex: colorHex, ownerId: userId)
            await reload()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func update(id: UUID, name: String, colorHex: String) async -> Bool {
        do {
            try await walletRepo.update(id: id, name: name, colorHex: colorHex)
            await reload()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete(id: UUID) async {
        do {
            try await walletRepo.delete(id: id)
            await reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
