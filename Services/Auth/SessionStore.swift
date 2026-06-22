import Foundation
import Observation

@MainActor
@Observable
final class SessionStore {
    var session: Session?
    private(set) var isLoading: Bool = true

    private let auth: AuthService

    init(auth: AuthService) {
        self.auth = auth
    }

    func bootstrap() async {
        isLoading = true
        session = await auth.currentSession()
        // If the stored token is expired, try a silent refresh.
        if session != nil {
            do { session = try await auth.refresh() } catch {
                // Refresh failed but we still have stored credentials — keep the
                // session alive; next real API call will re-attempt via refreshHandler.
            }
        }
        isLoading = false
    }

    func register(email: String, password: String) async throws {
        session = try await auth.register(email: email, password: password)
        NotificationCenter.default.post(name: .didAuthenticate, object: nil)
    }

    func login(email: String, password: String) async throws {
        session = try await auth.login(email: email, password: password)
        NotificationCenter.default.post(name: .didAuthenticate, object: nil)
    }

    func logout() async {
        await auth.logout()
        session = nil
    }

    var isAuthenticated: Bool { session != nil }
}

extension Notification.Name {
    static let didAuthenticate = Notification.Name("didAuthenticate")
}
