import Foundation
import Observation

@MainActor
@Observable
final class AuthViewModel {
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var isSubmitting: Bool = false
    var errorMessage: String?

    private let session: SessionStore

    init(session: SessionStore) {
        self.session = session
    }

    func login() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            try await session.login(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func register() async {
        guard !isSubmitting else { return }
        if password != confirmPassword {
            errorMessage = "Passwords do not match."
            return
        }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            try await session.register(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reset() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = nil
    }
}
