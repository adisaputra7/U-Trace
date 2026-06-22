import Foundation
import Observation

@MainActor
@Observable
final class CategoryViewModel {
    var categories: [CategoryModel] = []
    var errorMessage: String?

    private let categoryRepo: CategoryRepository
    private let session: SessionStore

    init(categoryRepo: CategoryRepository, session: SessionStore) {
        self.categoryRepo = categoryRepo
        self.session = session
    }

    func reload(scope: CategoryScope? = nil) async {
        guard let userId = session.session?.userId else { return }
        do {
            categories = try await categoryRepo.list(ownerId: userId, scope: scope)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func create(name: String, iconName: String, colorHex: String, scope: CategoryScope) async -> Bool {
        guard let userId = session.session?.userId else {
            errorMessage = "Not signed in."
            return false
        }
        do {
            _ = try await categoryRepo.create(name: name, iconName: iconName, colorHex: colorHex, scope: scope, ownerId: userId)
            await reload()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func update(id: UUID, name: String, iconName: String, colorHex: String, scope: CategoryScope) async -> Bool {
        do {
            try await categoryRepo.update(id: id, name: name, iconName: iconName, colorHex: colorHex, scope: scope)
            await reload()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete(id: UUID) async {
        do {
            try await categoryRepo.delete(id: id)
            await reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
