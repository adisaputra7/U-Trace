import Foundation

protocol AuthService: AnyObject {
    func currentSession() async -> Session?
    func register(email: String, password: String) async throws -> Session
    func login(email: String, password: String) async throws -> Session
    func logout() async
    func refresh() async throws -> Session
}

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailTaken
    case invalidCredentials
    case needsEmailVerification
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "Please enter a valid email address."
        case .weakPassword: return "Password must be at least 6 characters."
        case .emailTaken: return "This email is already registered."
        case .invalidCredentials: return "Email or password is incorrect."
        case .needsEmailVerification: return "Account created. Please verify your email before signing in."
        case .server(let msg): return msg
        }
    }
}

// MARK: - Insforge

@MainActor
final class InsforgeAuthService: AuthService {
    private let api: InsforgeAPIClient
    private let keychain: KeychainStore
    private let defaults: UserDefaults

    private let tokenKey        = "utrace.session.token"
    private let refreshKey      = "utrace.session.refresh"
    private let userIdKey       = "utrace.session.userId"
    private let emailKey        = "utrace.session.email"
    private let lastActivityKey = "utrace.session.lastActivity"

    /// Sessions older than this are treated as expired and require a fresh login.
    private let inactivityLimitSeconds: TimeInterval = 30 * 24 * 3600 // 30 days

    init(api: InsforgeAPIClient, keychain: KeychainStore? = nil, defaults: UserDefaults = .standard) {
        self.api = api
        self.keychain = keychain ?? KeychainStore()
        self.defaults = defaults
    }

    // MARK: - Public

    func currentSession() async -> Session? {
        guard let token = keychain.get(tokenKey),
              let idString = defaults.string(forKey: userIdKey),
              let userId = UUID(uuidString: idString),
              let email = defaults.string(forKey: emailKey) else { return nil }

        // Auto-logout after 30 days of inactivity.
        let lastActivity = defaults.double(forKey: lastActivityKey)
        if lastActivity > 0 {
            let elapsed = Date().timeIntervalSince1970 - lastActivity
            if elapsed > inactivityLimitSeconds {
                clearStoredSession()
                return nil
            }
        }

        let refresh = keychain.get(refreshKey)
        api.accessToken = token
        updateLastActivity()
        return Session(userId: userId, email: email, token: token, refreshToken: refresh)
    }

    func register(email: String, password: String) async throws -> Session {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        try Self.validate(email: normalizedEmail, password: password)

        do {
            let body = AuthSignupBody(email: normalizedEmail, password: password, name: nil)
            let response = try await api.send(.post, path: "/api/auth/users", body: body, as: AuthResponse.self)
            if response.accessToken == nil || response.requireEmailVerification == true {
                throw AuthError.needsEmailVerification
            }
            return try persist(response)
        } catch let APIError.server(code, msg) where code == 409 || msg.lowercased().contains("exist") {
            throw AuthError.emailTaken
        } catch let APIError.server(_, msg) {
            throw AuthError.server(msg)
        }
    }

    func login(email: String, password: String) async throws -> Session {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        try Self.validate(email: normalizedEmail, password: password)

        do {
            let body = AuthLoginBody(email: normalizedEmail, password: password)
            let response = try await api.send(.post, path: "/api/auth/sessions", body: body, as: AuthResponse.self)
            return try persist(response)
        } catch let APIError.server(code, _) where code == 401 || code == 400 {
            throw AuthError.invalidCredentials
        } catch let APIError.server(_, msg) {
            throw AuthError.server(msg)
        }
    }

    func logout() async {
        Task {
            do { try await api.sendVoid(.post, path: "/api/auth/logout") } catch {
                // Ignore network errors on logout; local state is cleared regardless.
            }
        }
        clearStoredSession()
    }

    func refresh() async throws -> Session {
        guard let refreshToken = keychain.get(refreshKey) else {
            throw AuthError.invalidCredentials
        }
        // Clear the (likely expired) bearer token before calling the refresh
        // endpoint so the server authenticates via the body's refreshToken only.
        let savedAccessToken = api.accessToken
        api.accessToken = nil
        do {
            let body = AuthRefreshBody(refreshToken: refreshToken)
            let response = try await api.send(
                .post,
                path: "/api/auth/refresh",
                query: [URLQueryItem(name: "client_type", value: "mobile")],
                body: body,
                as: AuthResponse.self
            )
            return try persist(response)
        } catch {
            api.accessToken = savedAccessToken
            throw error
        }
    }

    // MARK: - Private

    private func persist(_ response: AuthResponse) throws -> Session {
        guard let accessToken = response.accessToken else {
            throw AuthError.server("No access token returned by server.")
        }
        guard let userId = UUID(uuidString: response.user.id) else {
            throw AuthError.server("Server returned an invalid user id.")
        }
        try keychain.set(accessToken, for: tokenKey)
        if let refresh = response.refreshToken {
            try keychain.set(refresh, for: refreshKey)
        } else {
            keychain.delete(refreshKey)
        }
        defaults.set(userId.uuidString, forKey: userIdKey)
        defaults.set(response.user.email, forKey: emailKey)
        api.accessToken = accessToken
        updateLastActivity()
        return Session(
            userId: userId,
            email: response.user.email,
            token: accessToken,
            refreshToken: response.refreshToken
        )
    }

    /// Records current timestamp as last-activity marker (resets 30-day inactivity clock).
    private func updateLastActivity() {
        defaults.set(Date().timeIntervalSince1970, forKey: lastActivityKey)
    }

    /// Wipes all stored session data from Keychain + UserDefaults.
    private func clearStoredSession() {
        keychain.delete(tokenKey)
        keychain.delete(refreshKey)
        defaults.removeObject(forKey: userIdKey)
        defaults.removeObject(forKey: emailKey)
        defaults.removeObject(forKey: lastActivityKey)
        api.accessToken = nil
    }

    private static func validate(email: String, password: String) throws {
        if !email.contains("@") || !email.contains(".") || email.count < 5 {
            throw AuthError.invalidEmail
        }
        if password.count < 6 {
            throw AuthError.weakPassword
        }
    }
}

// MARK: - Wire DTOs

private struct AuthSignupBody: Encodable {
    let email: String
    let password: String
    let name: String?
}

private struct AuthLoginBody: Encodable {
    let email: String
    let password: String
}

private struct AuthRefreshBody: Encodable {
    let refreshToken: String
}

private struct AuthResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let csrfToken: String?
    let requireEmailVerification: Bool?
    let user: AuthUser
}

private struct AuthUser: Decodable {
    let id: String
    let email: String
}
