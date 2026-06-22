import Foundation

// MARK: - Enums

enum TxType: String, Codable, CaseIterable, Identifiable {
    case income = "INCOME"
    case expense = "EXPENSE"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .income: return "Income"
        case .expense: return "Expense"
        }
    }
}

enum CategoryScope: String, Codable, CaseIterable, Identifiable {
    case income = "INCOME"
    case expense = "EXPENSE"
    case all = "ALL"

    var id: String { rawValue }

    func matches(_ tx: TxType) -> Bool {
        switch self {
        case .all: return true
        case .income: return tx == .income
        case .expense: return tx == .expense
        }
    }
}

// MARK: - Domain models (cloud-backed, value types)

struct WalletModel: Identifiable, Codable, Hashable {
    var id: UUID
    var ownerUserId: UUID
    var familyId: UUID?
    var name: String
    var initialBalance: Decimal
    var balance: Decimal
    var colorHex: String
    var createdAt: Date

    /// Populated by the repository after fetching transactions; not persisted.
    var transactionCount: Int = 0

    enum CodingKeys: String, CodingKey {
        case id
        case ownerUserId = "owner_user_id"
        case familyId = "family_id"
        case name
        case initialBalance = "initial_balance"
        case balance
        case colorHex = "color_hex"
        case createdAt = "created_at"
    }

    init(
        id: UUID,
        ownerUserId: UUID,
        familyId: UUID? = nil,
        name: String,
        initialBalance: Decimal,
        balance: Decimal,
        colorHex: String,
        createdAt: Date,
        transactionCount: Int = 0
    ) {
        self.id = id
        self.ownerUserId = ownerUserId
        self.familyId = familyId
        self.name = name
        self.initialBalance = initialBalance
        self.balance = balance
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.transactionCount = transactionCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeFlexibleUUID(forKey: .id)
        ownerUserId = try c.decodeFlexibleUUID(forKey: .ownerUserId)
        familyId = try c.decodeFlexibleOptionalUUID(forKey: .familyId)
        name = try c.decode(String.self, forKey: .name)
        initialBalance = try c.decodeFlexibleDecimal(forKey: .initialBalance)
        balance = try c.decodeFlexibleDecimal(forKey: .balance)
        colorHex = try c.decode(String.self, forKey: .colorHex)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }
}

struct CategoryModel: Identifiable, Codable, Hashable {
    var id: UUID
    var ownerUserId: UUID?
    var name: String
    var iconName: String
    var colorHex: String
    var scope: CategoryScope
    var isSystem: Bool
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerUserId = "owner_user_id"
        case name
        case iconName = "icon_name"
        case colorHex = "color_hex"
        case scope
        case isSystem = "is_system"
        case createdAt = "created_at"
    }
}

struct TransactionModel: Identifiable, Codable, Hashable {
    var id: UUID
    var ownerUserId: UUID
    var familyId: UUID?
    var createdBy: UUID?
    var walletId: UUID
    var categoryId: UUID
    var amount: Decimal
    var type: TxType
    var date: Date
    var note: String?
    var createdAt: Date

    /// Joined client-side from local lookup; not persisted on the server row.
    var wallet: WalletModel?
    var category: CategoryModel?
    var createdByDisplayName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case ownerUserId = "owner_user_id"
        case familyId = "family_id"
        case createdBy = "created_by"
        case walletId = "wallet_id"
        case categoryId = "category_id"
        case amount
        case type
        case date
        case note
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeFlexibleUUID(forKey: .id)
        ownerUserId = try c.decodeFlexibleUUID(forKey: .ownerUserId)
        familyId = try c.decodeFlexibleOptionalUUID(forKey: .familyId)
        createdBy = try c.decodeFlexibleOptionalUUID(forKey: .createdBy)
        walletId = try c.decodeFlexibleUUID(forKey: .walletId)
        categoryId = try c.decodeFlexibleUUID(forKey: .categoryId)
        amount = try c.decodeFlexibleDecimal(forKey: .amount)
        type = try c.decode(TxType.self, forKey: .type)
        date = try c.decode(Date.self, forKey: .date)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }
}

// MARK: - Family Models

struct FamilyModel: Identifiable, Codable {
    let id: UUID
    let name: String
    let ownerUserId: UUID
    let inviteCode: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case ownerUserId = "owner_user_id"
        case inviteCode = "invite_code"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeFlexibleUUID(forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        ownerUserId = try c.decodeFlexibleUUID(forKey: .ownerUserId)
        inviteCode = try c.decode(String.self, forKey: .inviteCode)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }
}

struct FamilyMemberModel: Identifiable, Codable {
    let id: UUID
    let familyId: UUID
    let userId: UUID
    let displayName: String?
    let role: String
    let joinedAt: Date

    var isOwner: Bool { role == "owner" }

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case userId = "user_id"
        case displayName = "display_name"
        case role
        case joinedAt = "joined_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeFlexibleUUID(forKey: .id)
        familyId = try c.decodeFlexibleUUID(forKey: .familyId)
        userId = try c.decodeFlexibleUUID(forKey: .userId)
        displayName = try c.decodeIfPresent(String.self, forKey: .displayName)
        role = try c.decode(String.self, forKey: .role)
        joinedAt = try c.decode(Date.self, forKey: .joinedAt)
    }
}

// MARK: - Flexible decoders for PostgREST (numeric may come as string)

private extension KeyedDecodingContainer {
    func decodeFlexibleDecimal(forKey key: Key) throws -> Decimal {
        if let number = try? decode(Decimal.self, forKey: key) { return number }
        if let str = try? decode(String.self, forKey: key), let value = Decimal(string: str) {
            return value
        }
        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: self,
            debugDescription: "Expected number or numeric string for \(key.stringValue)"
        )
    }

    func decodeFlexibleUUID(forKey key: Key) throws -> UUID {
        let raw = try decode(String.self, forKey: key)
        if let uuid = UUID(uuidString: raw) { return uuid }
        if raw.count == 32 {
            let s = raw
            let formatted = "\(s.prefix(8))-\(s.dropFirst(8).prefix(4))-\(s.dropFirst(12).prefix(4))-\(s.dropFirst(16).prefix(4))-\(s.dropFirst(20))"
            if let uuid = UUID(uuidString: formatted) { return uuid }
        }
        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: self,
            debugDescription: "Invalid UUID string for \(key.stringValue): \(raw)"
        )
    }

    func decodeFlexibleOptionalUUID(forKey key: Key) throws -> UUID? {
        guard let raw = try decodeIfPresent(String.self, forKey: key), !raw.isEmpty else { return nil }
        if let uuid = UUID(uuidString: raw) { return uuid }
        if raw.count == 32 {
            let s = raw
            let formatted = "\(s.prefix(8))-\(s.dropFirst(8).prefix(4))-\(s.dropFirst(12).prefix(4))-\(s.dropFirst(16).prefix(4))-\(s.dropFirst(20))"
            if let uuid = UUID(uuidString: formatted) { return uuid }
        }
        return nil
    }
}

// MARK: - DTOs

struct Session: Codable, Equatable {
    let userId: UUID
    let email: String
    let token: String
    let refreshToken: String?
}

struct TransactionDraft {
    var amount: Decimal
    var type: TxType
    var date: Date
    var note: String?
    var walletId: UUID
    var categoryId: UUID
    var createdBy: UUID?
}

struct TxFilter {
    var startDate: Date?
    var endDate: Date?
    var walletId: UUID?
    var categoryId: UUID?
    var type: TxType?

    static let none = TxFilter()
}

struct PageRequest {
    var offset: Int
    var limit: Int
    static let firstPage = PageRequest(offset: 0, limit: 20)
}

struct MonthlyTotal: Identifiable {
    var id: String { "\(year)-\(month)" }
    let year: Int
    let month: Int
    let income: Decimal
    let expense: Decimal
}
