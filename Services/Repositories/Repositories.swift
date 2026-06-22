import Foundation

protocol WalletRepository {
    func list(ownerId: UUID) async throws -> [WalletModel]
    func find(id: UUID) async throws -> WalletModel?
    func create(name: String, balance: Decimal, colorHex: String, ownerId: UUID) async throws -> WalletModel
    func update(id: UUID, name: String, colorHex: String) async throws
    func delete(id: UUID) async throws
    func recomputeBalance(walletId: UUID) async throws
}

protocol CategoryRepository {
    /// Returns both system categories and user-owned categories.
    func list(ownerId: UUID, scope: CategoryScope?) async throws -> [CategoryModel]
    func find(id: UUID) async throws -> CategoryModel?
    func create(name: String, iconName: String, colorHex: String, scope: CategoryScope, ownerId: UUID) async throws -> CategoryModel
    func update(id: UUID, name: String, iconName: String, colorHex: String, scope: CategoryScope) async throws
    func delete(id: UUID) async throws
    func seedSystemCategoriesIfNeeded() async throws
}

protocol TransactionRepository {
    func create(_ draft: TransactionDraft, ownerId: UUID) async throws -> TransactionModel
    func list(ownerId: UUID, filter: TxFilter, page: PageRequest) async throws -> [TransactionModel]
    func delete(id: UUID) async throws
    func monthlyTotals(ownerId: UUID, year: Int) async throws -> [MonthlyTotal]
    func totalsForPeriod(ownerId: UUID, start: Date, end: Date) async throws -> (income: Decimal, expense: Decimal)
}

protocol FamilyRepository {
    func myFamily(userId: UUID) async throws -> FamilyModel?
    func create(name: String, ownerId: UUID, displayName: String) async throws -> FamilyModel
    func join(inviteCode: String, userId: UUID, displayName: String) async throws -> FamilyModel
    func members(familyId: UUID) async throws -> [FamilyMemberModel]
    func leave(familyId: UUID, userId: UUID) async throws
    func disband(familyId: UUID) async throws
    func migrateData(userId: UUID, toFamily familyId: UUID) async throws
}

enum RepositoryError: Error, LocalizedError {
    case notFound
    case duplicate
    case invalid(String)

    var errorDescription: String? {
        switch self {
        case .notFound: return "Item not found."
        case .duplicate: return "Item already exists."
        case .invalid(let msg): return msg
        }
    }
}
