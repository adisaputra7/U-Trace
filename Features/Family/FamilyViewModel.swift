import Foundation
import Observation

@MainActor
@Observable
final class FamilyViewModel {
    private let familyRepo: any FamilyRepository
    private let session: SessionStore
    private let env: AppEnvironment

    var family: FamilyModel?
    var members: [FamilyMemberModel] = []
    var isLoading = false
    var errorMessage: String?

    init(familyRepo: any FamilyRepository, session: SessionStore, env: AppEnvironment) {
        self.familyRepo = familyRepo
        self.session = session
        self.env = env
        self.family = env.currentFamily
    }

    func reload() async {
        guard let userId = session.session?.userId else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            family = try await familyRepo.myFamily(userId: userId)
            env.currentFamily = family
            env.api.currentFamilyId = family?.id
            if let familyId = family?.id {
                members = try await familyRepo.members(familyId: familyId)
            } else {
                members = []
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createFamily(name: String) async {
        guard let userId = session.session?.userId else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { errorMessage = "Nama keluarga tidak boleh kosong."; return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let displayName = session.session?.email.split(separator: "@").first.map(String.init) ?? "Owner"
            let created = try await familyRepo.create(name: trimmed, ownerId: userId, displayName: displayName)
            try await familyRepo.migrateData(userId: userId, toFamily: created.id)
            env.currentFamily = created
            env.api.currentFamilyId = created.id
            family = created
            members = try await familyRepo.members(familyId: created.id)
            NotificationCenter.default.post(name: .familyDidChange, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func joinFamily(code: String) async {
        guard let userId = session.session?.userId else { return }
        let trimmed = code.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { errorMessage = "Masukkan kode undangan."; return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let displayName = session.session?.email.split(separator: "@").first.map(String.init) ?? "Anggota"
            let joined = try await familyRepo.join(inviteCode: trimmed, userId: userId, displayName: displayName)
            try await familyRepo.migrateData(userId: userId, toFamily: joined.id)
            env.currentFamily = joined
            env.api.currentFamilyId = joined.id
            family = joined
            members = try await familyRepo.members(familyId: joined.id)
            NotificationCenter.default.post(name: .familyDidChange, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func leaveFamily() async {
        guard let familyId = family?.id, let userId = session.session?.userId else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await familyRepo.leave(familyId: familyId, userId: userId)
            clearFamily()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func disbandFamily() async {
        guard let familyId = family?.id else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await familyRepo.disband(familyId: familyId)
            clearFamily()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var isOwner: Bool {
        guard let family, let userId = session.session?.userId else { return false }
        return family.ownerUserId == userId
    }

    private func clearFamily() {
        env.currentFamily = nil
        env.api.currentFamilyId = nil
        family = nil
        members = []
        NotificationCenter.default.post(name: .familyDidChange, object: nil)
    }
}

extension Notification.Name {
    static let familyDidChange = Notification.Name("familyDidChange")
}
