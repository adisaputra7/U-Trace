import Foundation

// MARK: - Filter helpers

private extension URLQueryItem {
    static func eq(_ column: String, _ value: String) -> URLQueryItem {
        URLQueryItem(name: column, value: "eq.\(value)")
    }
    static func gte(_ column: String, _ value: String) -> URLQueryItem {
        URLQueryItem(name: column, value: "gte.\(value)")
    }
    static func lte(_ column: String, _ value: String) -> URLQueryItem {
        URLQueryItem(name: column, value: "lte.\(value)")
    }
    static func inList(_ column: String, _ values: [String]) -> URLQueryItem {
        URLQueryItem(name: column, value: "in.(\(values.joined(separator: ",")))")
    }
    static func order(_ value: String) -> URLQueryItem {
        URLQueryItem(name: "order", value: value)
    }
    static func limit(_ value: Int) -> URLQueryItem {
        URLQueryItem(name: "limit", value: String(value))
    }
    static func offset(_ value: Int) -> URLQueryItem {
        URLQueryItem(name: "offset", value: String(value))
    }
}

private func iso(_ date: Date) -> String { ISO8601Helpers.format(date) }

// MARK: - Wallets

@MainActor
final class InsforgeWalletRepository: WalletRepository {
    private let api: InsforgeAPIClient
    private let txCounter: TransactionCounter

    init(api: InsforgeAPIClient, txCounter: TransactionCounter) {
        self.api = api
        self.txCounter = txCounter
    }

    func list(ownerId: UUID) async throws -> [WalletModel] {
        let ownerFilter: URLQueryItem = api.currentFamilyId.map { .eq("family_id", $0.uuidString) }
            ?? .eq("owner_user_id", ownerId.uuidString)
        var wallets = try await api.send(
            .get,
            path: "/api/database/records/wallets",
            query: [ownerFilter, .order("created_at.asc"), .limit(1000)],
            as: [WalletModel].self
        )
        let counts = try await txCounter.countsPerWallet(ownerId: ownerId)
        for index in wallets.indices {
            wallets[index].transactionCount = counts[wallets[index].id] ?? 0
        }
        return wallets
    }

    func find(id: UUID) async throws -> WalletModel? {
        let rows = try await api.send(
            .get,
            path: "/api/database/records/wallets",
            query: [.eq("id", id.uuidString), .limit(1)],
            as: [WalletModel].self
        )
        return rows.first
    }

    func create(name: String, balance: Decimal, colorHex: String, ownerId: UUID) async throws -> WalletModel {
        let payload = WalletInsertPayload(
            ownerUserId: ownerId,
            familyId: api.currentFamilyId,
            name: name,
            initialBalance: balance,
            balance: balance,
            colorHex: colorHex
        )
        let response = try await api.send(
            .post,
            path: "/api/database/records/wallets",
            body: [payload],
            preferReturnRepresentation: true,
            as: [WalletModel].self
        )
        if let created = response.first { return created }
        // Server omitted body even with Prefer header; fetch newest wallet by owner.
        let rows = try await api.send(
            .get,
            path: "/api/database/records/wallets",
            query: [
                .eq("owner_user_id", ownerId.uuidString),
                .order("created_at.desc"),
                .limit(1)
            ],
            as: [WalletModel].self
        )
        guard let created = rows.first else { throw RepositoryError.invalid("Server did not return wallet.") }
        return created
    }

    func update(id: UUID, name: String, colorHex: String) async throws {
        let body = WalletUpdatePatch(name: name, colorHex: colorHex)
        try await api.sendVoid(
            .patch,
            path: "/api/database/records/wallets",
            query: [.eq("id", id.uuidString)],
            body: body
        )
    }

    func delete(id: UUID) async throws {
        try await api.sendVoid(
            .delete,
            path: "/api/database/records/transactions",
            query: [.eq("wallet_id", id.uuidString)]
        )
        try await api.sendVoid(
            .delete,
            path: "/api/database/records/wallets",
            query: [.eq("id", id.uuidString)]
        )
    }

    func recomputeBalance(walletId: UUID) async throws {
        guard let wallet = try await find(id: walletId) else { throw RepositoryError.notFound }
        let txs = try await api.send(
            .get,
            path: "/api/database/records/transactions",
            query: [
                .eq("wallet_id", walletId.uuidString),
                .limit(1000)
            ],
            as: [TransactionModel].self
        )
        var income: Decimal = 0
        var expense: Decimal = 0
        for tx in txs {
            if tx.type == .income { income += tx.amount } else { expense += tx.amount }
        }
        let newBalance = wallet.initialBalance + income - expense
        let patch = WalletBalancePatch(balance: newBalance)
        try await api.sendVoid(
            .patch,
            path: "/api/database/records/wallets",
            query: [.eq("id", walletId.uuidString)],
            body: patch
        )
    }
}

private struct WalletInsertPayload: Encodable {
    let ownerUserId: UUID
    let familyId: UUID?
    let name: String
    let initialBalance: Decimal
    let balance: Decimal
    let colorHex: String

    enum CodingKeys: String, CodingKey {
        case ownerUserId = "owner_user_id"
        case familyId = "family_id"
        case name
        case initialBalance = "initial_balance"
        case balance
        case colorHex = "color_hex"
    }
}

private struct WalletUpdatePatch: Encodable {
    let name: String
    let colorHex: String

    enum CodingKeys: String, CodingKey {
        case name
        case colorHex = "color_hex"
    }
}

private struct WalletBalancePatch: Encodable {
    let balance: Decimal
}

// MARK: - Categories

@MainActor
final class InsforgeCategoryRepository: CategoryRepository {
    private let api: InsforgeAPIClient

    init(api: InsforgeAPIClient) {
        self.api = api
    }

    func list(ownerId: UUID, scope: CategoryScope?) async throws -> [CategoryModel] {
        async let systemTask = api.send(
            .get,
            path: "/api/database/records/categories",
            query: [.eq("is_system", "true"), .order("created_at.asc"), .limit(1000)],
            as: [CategoryModel].self
        )
        async let userTask = api.send(
            .get,
            path: "/api/database/records/categories",
            query: [.eq("owner_user_id", ownerId.uuidString), .order("created_at.asc"), .limit(1000)],
            as: [CategoryModel].self
        )
        let all = try await systemTask + userTask
        return all.filter { cat in
            if let scope, scope != .all {
                return cat.scope == scope || cat.scope == .all
            }
            return true
        }
    }

    func find(id: UUID) async throws -> CategoryModel? {
        let rows = try await api.send(
            .get,
            path: "/api/database/records/categories",
            query: [.eq("id", id.uuidString), .limit(1)],
            as: [CategoryModel].self
        )
        return rows.first
    }

    func create(name: String, iconName: String, colorHex: String, scope: CategoryScope, ownerId: UUID) async throws -> CategoryModel {
        let payload = CategoryInsertPayload(
            ownerUserId: ownerId,
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            scope: scope,
            isSystem: false
        )
        let response = try await api.send(
            .post,
            path: "/api/database/records/categories",
            body: [payload],
            preferReturnRepresentation: true,
            as: [CategoryModel].self
        )
        if let created = response.first { return created }
        let rows = try await api.send(
            .get,
            path: "/api/database/records/categories",
            query: [
                .eq("owner_user_id", ownerId.uuidString),
                .order("created_at.desc"),
                .limit(1)
            ],
            as: [CategoryModel].self
        )
        guard let created = rows.first else { throw RepositoryError.invalid("Server did not return category.") }
        return created
    }

    func update(id: UUID, name: String, iconName: String, colorHex: String, scope: CategoryScope) async throws {
        guard let cat = try await find(id: id) else { throw RepositoryError.notFound }
        if cat.isSystem { throw RepositoryError.invalid("System categories cannot be edited.") }
        let body = CategoryUpdatePatch(name: name, iconName: iconName, colorHex: colorHex, scope: scope)
        try await api.sendVoid(
            .patch,
            path: "/api/database/records/categories",
            query: [.eq("id", id.uuidString)],
            body: body
        )
    }

    func delete(id: UUID) async throws {
        guard let cat = try await find(id: id) else { throw RepositoryError.notFound }
        if cat.isSystem { throw RepositoryError.invalid("System categories cannot be deleted.") }
        try await api.sendVoid(
            .delete,
            path: "/api/database/records/categories",
            query: [.eq("id", id.uuidString)]
        )
    }

    func seedSystemCategoriesIfNeeded() async throws {
        let existing = try await api.send(
            .get,
            path: "/api/database/records/categories",
            query: [.eq("is_system", "true"), .limit(1)],
            as: [CategoryModel].self
        )
        guard existing.isEmpty else { return }

        let seeds: [(String, String, String, CategoryScope)] = [
            ("Salary", "banknote.fill", "#7CFFCB", .income),
            ("Bonus", "gift.fill", "#FFD37C", .income),
            ("Investment", "chart.line.uptrend.xyaxis", "#7CD8FF", .income),
            ("Food", "fork.knife", "#FF7CCB", .expense),
            ("Transport", "car.fill", "#7CD8FF", .expense),
            ("Shopping", "bag.fill", "#FFD37C", .expense),
            ("Bills", "doc.text.fill", "#FF6B7A", .expense),
            ("Entertainment", "gamecontroller.fill", "#FF7CCB", .expense),
            ("Health", "heart.fill", "#7CFFCB", .expense),
            ("Education", "graduationcap.fill", "#7CD8FF", .expense),
            ("Travel", "airplane", "#FFD37C", .expense),
            ("Other", "ellipsis.circle.fill", "#A0A0B0", .all)
        ]
        let rows = seeds.map { (name, icon, color, scope) in
            CategoryInsertPayload(
                ownerUserId: nil,
                name: name,
                iconName: icon,
                colorHex: color,
                scope: scope,
                isSystem: true
            )
        }
        try await api.sendVoid(
            .post,
            path: "/api/database/records/categories",
            body: rows
        )
    }
}

private struct CategoryInsertPayload: Encodable {
    let ownerUserId: UUID?
    let name: String
    let iconName: String
    let colorHex: String
    let scope: CategoryScope
    let isSystem: Bool

    enum CodingKeys: String, CodingKey {
        case ownerUserId = "owner_user_id"
        case name
        case iconName = "icon_name"
        case colorHex = "color_hex"
        case scope
        case isSystem = "is_system"
    }
}

private struct CategoryUpdatePatch: Encodable {
    let name: String
    let iconName: String
    let colorHex: String
    let scope: CategoryScope

    enum CodingKeys: String, CodingKey {
        case name
        case iconName = "icon_name"
        case colorHex = "color_hex"
        case scope
    }
}

// MARK: - Transactions

@MainActor
final class InsforgeTransactionRepository: TransactionRepository {
    private let api: InsforgeAPIClient
    private let walletRepo: WalletRepository

    init(api: InsforgeAPIClient, walletRepo: WalletRepository) {
        self.api = api
        self.walletRepo = walletRepo
    }

    func create(_ draft: TransactionDraft, ownerId: UUID) async throws -> TransactionModel {
        let payload = TransactionInsertPayload(
            ownerUserId: ownerId,
            familyId: api.currentFamilyId,
            createdBy: draft.createdBy,
            walletId: draft.walletId,
            categoryId: draft.categoryId,
            amount: draft.amount,
            type: draft.type,
            date: draft.date,
            note: draft.note
        )
        let response = try await api.send(
            .post,
            path: "/api/database/records/transactions",
            body: [payload],
            preferReturnRepresentation: true,
            as: [TransactionModel].self
        )
        let created: TransactionModel
        if let first = response.first {
            created = first
        } else {
            let rows = try await api.send(
                .get,
                path: "/api/database/records/transactions",
                query: [
                    .eq("owner_user_id", ownerId.uuidString),
                    .order("created_at.desc"),
                    .limit(1)
                ],
                as: [TransactionModel].self
            )
            guard let row = rows.first else { throw RepositoryError.invalid("Server did not return transaction.") }
            created = row
        }
        try await walletRepo.recomputeBalance(walletId: draft.walletId)
        return created
    }

    func list(ownerId: UUID, filter: TxFilter, page: PageRequest) async throws -> [TransactionModel] {
        let ownerFilter: URLQueryItem = api.currentFamilyId.map { .eq("family_id", $0.uuidString) }
            ?? .eq("owner_user_id", ownerId.uuidString)
        var query: [URLQueryItem] = [
            ownerFilter,
            .order("date.desc,created_at.desc"),
            .limit(page.limit),
            .offset(page.offset)
        ]
        if let walletId = filter.walletId { query.append(.eq("wallet_id", walletId.uuidString)) }
        if let categoryId = filter.categoryId { query.append(.eq("category_id", categoryId.uuidString)) }
        if let type = filter.type { query.append(.eq("type", type.rawValue)) }
        if let start = filter.startDate { query.append(.gte("date", iso(start))) }
        if let end = filter.endDate { query.append(.lte("date", iso(end))) }

        let rows = try await api.send(
            .get,
            path: "/api/database/records/transactions",
            query: query,
            as: [TransactionModel].self
        )
        return try await hydrate(rows: rows, ownerId: ownerId)
    }

    func delete(id: UUID) async throws {
        let rows = try await api.send(
            .get,
            path: "/api/database/records/transactions",
            query: [.eq("id", id.uuidString), .limit(1)],
            as: [TransactionModel].self
        )
        guard let tx = rows.first else { throw RepositoryError.notFound }
        try await api.sendVoid(
            .delete,
            path: "/api/database/records/transactions",
            query: [.eq("id", id.uuidString)]
        )
        try await walletRepo.recomputeBalance(walletId: tx.walletId)
    }

    func monthlyTotals(ownerId: UUID, year: Int) async throws -> [MonthlyTotal] {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: year, month: 1, day: 1)
        let endComponents = DateComponents(year: year + 1, month: 1, day: 1)
        guard let start = calendar.date(from: startComponents),
              let end = calendar.date(from: endComponents) else { return [] }

        let ownerFilter: URLQueryItem = api.currentFamilyId.map { .eq("family_id", $0.uuidString) }
            ?? .eq("owner_user_id", ownerId.uuidString)
        let rows = try await api.send(
            .get,
            path: "/api/database/records/transactions",
            query: [ownerFilter, .gte("date", iso(start)), .lte("date", iso(end)), .limit(10_000)],
            as: [TransactionModel].self
        )

        var buckets: [Int: (income: Decimal, expense: Decimal)] = [:]
        for tx in rows {
            let components = calendar.dateComponents([.year, .month], from: tx.date)
            guard components.year == year, let month = components.month else { continue }
            var current = buckets[month] ?? (income: 0, expense: 0)
            if tx.type == .income { current.income += tx.amount } else { current.expense += tx.amount }
            buckets[month] = current
        }
        return (1...12).map { month in
            let totals = buckets[month] ?? (income: 0, expense: 0)
            return MonthlyTotal(year: year, month: month, income: totals.income, expense: totals.expense)
        }
    }

    func totalsForPeriod(ownerId: UUID, start: Date, end: Date) async throws -> (income: Decimal, expense: Decimal) {
        let ownerFilter: URLQueryItem = api.currentFamilyId.map { .eq("family_id", $0.uuidString) }
            ?? .eq("owner_user_id", ownerId.uuidString)
        let rows = try await api.send(
            .get,
            path: "/api/database/records/transactions",
            query: [ownerFilter, .gte("date", iso(start)), .lte("date", iso(end)), .limit(10_000)],
            as: [TransactionModel].self
        )
        var income: Decimal = 0
        var expense: Decimal = 0
        for tx in rows {
            if tx.type == .income { income += tx.amount } else { expense += tx.amount }
        }
        return (income, expense)
    }

    // MARK: - Hydration

    private func hydrate(rows: [TransactionModel], ownerId: UUID) async throws -> [TransactionModel] {
        guard !rows.isEmpty else { return rows }
        let walletIds = Set(rows.map(\.walletId))
        let categoryIds = Set(rows.map(\.categoryId))

        let walletFilter: URLQueryItem = api.currentFamilyId.map { .eq("family_id", $0.uuidString) }
            ?? .eq("owner_user_id", ownerId.uuidString)

        // Capture before async let to avoid main-actor isolation issues inside child tasks.
        let currentFamilyId = api.currentFamilyId

        async let walletsTask = api.send(
            .get,
            path: "/api/database/records/wallets",
            query: [walletFilter, .limit(1000)],
            as: [WalletModel].self
        )
        // Fetch all categories referenced by these transactions directly by ID,
        // so cross-member categories (other family members' custom categories) are included.
        let categoryIdStrings = Array(categoryIds).map(\.uuidString)
        async let catsTask = api.send(
            .get,
            path: "/api/database/records/categories",
            query: [.inList("id", categoryIdStrings), .limit(1000)],
            as: [CategoryModel].self
        )

        let wallets = (try await walletsTask).filter { walletIds.contains($0.id) }
        let cats = try await catsTask

        // Resolve creator display names from family_members (small dataset, fast fetch).
        var memberNameMap: [UUID: String] = [:]
        if let familyId = currentFamilyId {
            let members = (try? await api.send(
                .get,
                path: "/api/database/records/family_members",
                query: [.eq("family_id", familyId.uuidString), .limit(100)],
                as: [FamilyMemberModel].self
            )) ?? []
            memberNameMap = members.reduce(into: [:]) { acc, m in
                if let name = m.displayName { acc[m.userId] = name }
            }
        }

        let walletMap = Dictionary(uniqueKeysWithValues: wallets.map { ($0.id, $0) })
        let catMap = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0) })

        let inFamily = currentFamilyId != nil
        return rows.map { tx in
            var copy = tx
            copy.wallet = walletMap[tx.walletId]
            copy.category = catMap[tx.categoryId]
            if inFamily, let createdBy = tx.createdBy, createdBy != ownerId {
                copy.createdByDisplayName = memberNameMap[createdBy]
            }
            return copy
        }
    }
}

private struct TransactionInsertPayload: Encodable {
    let ownerUserId: UUID
    let familyId: UUID?
    let createdBy: UUID?
    let walletId: UUID
    let categoryId: UUID
    let amount: Decimal
    let type: TxType
    let date: Date
    let note: String?

    enum CodingKeys: String, CodingKey {
        case ownerUserId = "owner_user_id"
        case familyId = "family_id"
        case createdBy = "created_by"
        case walletId = "wallet_id"
        case categoryId = "category_id"
        case amount, type, date, note
    }
}

// MARK: - Helpers

@MainActor
final class TransactionCounter {
    private let api: InsforgeAPIClient

    init(api: InsforgeAPIClient) { self.api = api }

    func countsPerWallet(ownerId: UUID) async throws -> [UUID: Int] {
        let ownerFilter: URLQueryItem = api.currentFamilyId.map { .eq("family_id", $0.uuidString) }
            ?? .eq("owner_user_id", ownerId.uuidString)
        let rows = try await api.send(
            .get,
            path: "/api/database/records/transactions",
            query: [ownerFilter, .limit(10_000)],
            as: [TransactionStub].self
        )
        var counts: [UUID: Int] = [:]
        for row in rows { counts[row.walletId, default: 0] += 1 }
        return counts
    }
}

private struct TransactionStub: Decodable {
    let walletId: UUID

    enum CodingKeys: String, CodingKey {
        case walletId = "wallet_id"
    }
}

// MARK: - Family

@MainActor
final class InsforgeFamilyRepository: FamilyRepository {
    private let api: InsforgeAPIClient

    init(api: InsforgeAPIClient) { self.api = api }

    func myFamily(userId: UUID) async throws -> FamilyModel? {
        let memberships = try await api.send(
            .get,
            path: "/api/database/records/family_members",
            query: [.eq("user_id", userId.uuidString), .limit(1)],
            as: [FamilyMemberModel].self
        )
        guard let m = memberships.first else { return nil }
        let families = try await api.send(
            .get,
            path: "/api/database/records/families",
            query: [.eq("id", m.familyId.uuidString), .limit(1)],
            as: [FamilyModel].self
        )
        return families.first
    }

    func create(name: String, ownerId: UUID, displayName: String) async throws -> FamilyModel {
        let response = try await api.send(
            .post,
            path: "/api/database/records/families",
            body: [FamilyInsertPayload(name: name, ownerUserId: ownerId)],
            preferReturnRepresentation: true,
            as: [FamilyModel].self
        )
        let family: FamilyModel
        if let created = response.first {
            family = created
        } else {
            let rows = try await api.send(
                .get,
                path: "/api/database/records/families",
                query: [.eq("owner_user_id", ownerId.uuidString), .order("created_at.desc"), .limit(1)],
                as: [FamilyModel].self
            )
            guard let created = rows.first else { throw RepositoryError.invalid("Family tidak berhasil dibuat.") }
            family = created
        }
        try await api.sendVoid(
            .post,
            path: "/api/database/records/family_members",
            body: [MemberInsertPayload(familyId: family.id, userId: ownerId, displayName: displayName, role: "owner")]
        )
        return family
    }

    func join(inviteCode: String, userId: UUID, displayName: String) async throws -> FamilyModel {
        let families = try await api.send(
            .get,
            path: "/api/database/records/families",
            query: [.eq("invite_code", inviteCode.uppercased()), .limit(1)],
            as: [FamilyModel].self
        )
        guard let family = families.first else {
            throw RepositoryError.invalid("Kode undangan tidak valid.")
        }
        let existing = try await api.send(
            .get,
            path: "/api/database/records/family_members",
            query: [.eq("family_id", family.id.uuidString), .eq("user_id", userId.uuidString), .limit(1)],
            as: [FamilyMemberModel].self
        )
        if existing.isEmpty {
            try await api.sendVoid(
                .post,
                path: "/api/database/records/family_members",
                body: [MemberInsertPayload(familyId: family.id, userId: userId, displayName: displayName, role: "member")]
            )
        }
        return family
    }

    func members(familyId: UUID) async throws -> [FamilyMemberModel] {
        try await api.send(
            .get,
            path: "/api/database/records/family_members",
            query: [.eq("family_id", familyId.uuidString), .order("joined_at.asc"), .limit(100)],
            as: [FamilyMemberModel].self
        )
    }

    func leave(familyId: UUID, userId: UUID) async throws {
        try await api.sendVoid(
            .delete,
            path: "/api/database/records/family_members",
            query: [.eq("family_id", familyId.uuidString), .eq("user_id", userId.uuidString)]
        )
    }

    func disband(familyId: UUID) async throws {
        try await api.sendVoid(
            .delete,
            path: "/api/database/records/families",
            query: [.eq("id", familyId.uuidString)]
        )
    }

    func migrateData(userId: UUID, toFamily familyId: UUID) async throws {
        let patch = FamilyIdPatch(familyId: familyId)
        async let walletTask: Void = api.sendVoid(
            .patch,
            path: "/api/database/records/wallets",
            query: [.eq("owner_user_id", userId.uuidString)],
            body: patch
        )
        async let txTask: Void = api.sendVoid(
            .patch,
            path: "/api/database/records/transactions",
            query: [.eq("owner_user_id", userId.uuidString)],
            body: patch
        )
        _ = try await (walletTask, txTask)
    }
}

private struct FamilyInsertPayload: Encodable {
    let name: String
    let ownerUserId: UUID
    enum CodingKeys: String, CodingKey {
        case name
        case ownerUserId = "owner_user_id"
    }
}

private struct MemberInsertPayload: Encodable {
    let familyId: UUID
    let userId: UUID
    let displayName: String
    let role: String
    enum CodingKeys: String, CodingKey {
        case familyId = "family_id"
        case userId = "user_id"
        case displayName = "display_name"
        case role
    }
}

private struct FamilyIdPatch: Encodable {
    let familyId: UUID

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(familyId, forKey: .familyId)
    }

    enum CodingKeys: String, CodingKey { case familyId = "family_id" }
}
