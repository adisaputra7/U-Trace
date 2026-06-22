import Foundation

/// Minimal REST client for Insforge.
///
/// Auth flow:
///   POST /api/auth/users     -> { accessToken, refreshToken, user }     (sign up)
///   POST /api/auth/sessions  -> { accessToken, refreshToken, user }     (sign in)
///   POST /api/auth/logout
///
/// Database (PostgREST-style autogen):
///   GET    /api/database/records/{table}?col=eq.value&order=col.desc&limit=N&offset=N
///   POST   /api/database/records/{table}     body: [ {...}, ... ]  (array required)
///   PATCH  /api/database/records/{table}?id=eq.<id>   body: { ... }
///   DELETE /api/database/records/{table}?id=eq.<id>
@MainActor
final class InsforgeAPIClient {
    let baseURL: URL
    let anonKey: String
    var accessToken: String?

    /// Set when the user belongs to a family. Repositories use this to filter
    /// by `family_id` instead of `owner_user_id`.
    var currentFamilyId: UUID?

    /// Invoked when a request returns 401. Should refresh the access token (and
    /// update `accessToken`) or throw if the session can no longer be recovered.
    var refreshHandler: (() async throws -> Void)?

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var pendingRefresh: Task<Void, Error>?

    init(baseURL: URL? = nil, anonKey: String? = nil) {
        self.baseURL = baseURL ?? InsforgeConfig.baseURL
        self.anonKey = anonKey ?? InsforgeConfig.anonKey
        self.session = URLSession(configuration: .default)

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601WithFractionalSeconds
        self.decoder = dec

        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601WithFractionalSeconds
        self.encoder = enc
    }

    // MARK: - Public entry points

    @discardableResult
    func send<R: Decodable>(
        _ method: HTTPMethod,
        path: String,
        query: [URLQueryItem] = [],
        body: Encodable? = nil,
        preferReturnRepresentation: Bool = false,
        as type: R.Type
    ) async throws -> R {
        let data = try await sendRaw(
            method,
            path: path,
            query: query,
            body: body,
            preferReturnRepresentation: preferReturnRepresentation
        )
        if R.self == EmptyResponse.self {
            return EmptyResponse() as! R
        }
        do {
            return try decoder.decode(R.self, from: data)
        } catch {
            #if DEBUG
            let preview = String(data: data, encoding: .utf8) ?? "<binary>"
            print("[Insforge] Decode failed for \(path). Body: \(preview)")
            #endif
            throw APIError.decoding(error)
        }
    }

    func sendVoid(
        _ method: HTTPMethod,
        path: String,
        query: [URLQueryItem] = [],
        body: Encodable? = nil
    ) async throws {
        _ = try await sendRaw(method, path: path, query: query, body: body, preferReturnRepresentation: false)
    }

    // MARK: - Core

    private func sendRaw(
        _ method: HTTPMethod,
        path: String,
        query: [URLQueryItem],
        body: Encodable?,
        preferReturnRepresentation: Bool
    ) async throws -> Data {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if !query.isEmpty { components?.queryItems = query }
        guard let url = components?.url else { throw APIError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        applyAuthorization(to: &request)
        if preferReturnRepresentation {
            request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        }
        if let body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        var didRetryAfterRefresh = false
        while true {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

            if http.statusCode == 401,
               !didRetryAfterRefresh,
               refreshHandler != nil,
               !path.hasPrefix("/api/auth/") {
                do {
                    try await runRefresh()
                } catch {
                    throw APIError.unauthenticated
                }
                applyAuthorization(to: &request)
                didRetryAfterRefresh = true
                continue
            }

            guard (200..<300).contains(http.statusCode) else {
                if let err = try? decoder.decode(InsforgeErrorResponse.self, from: data) {
                    throw APIError.server(http.statusCode, err.message)
                }
                let body = String(data: data, encoding: .utf8) ?? "<no body>"
                throw APIError.http(http.statusCode, body)
            }
            return data
        }
    }

    private func applyAuthorization(to request: inout URLRequest) {
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }
    }

    /// Single-flight wrapper around `refreshHandler` so concurrent 401s don't
    /// trigger multiple refresh requests.
    private func runRefresh() async throws {
        if let existing = pendingRefresh {
            try await existing.value
            return
        }
        guard let handler = refreshHandler else { throw APIError.unauthenticated }
        let task = Task<Void, Error> { @MainActor in
            try await handler()
        }
        pendingRefresh = task
        do {
            try await task.value
            pendingRefresh = nil
        } catch {
            pendingRefresh = nil
            throw error
        }
    }
}

// MARK: - Supporting types

enum HTTPMethod: String {
    case get = "GET", post = "POST", patch = "PATCH", put = "PUT", delete = "DELETE"
}

struct EmptyResponse: Decodable {}

private struct AnyEncodable: Encodable {
    let value: Encodable
    init(_ value: Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
}

struct InsforgeErrorResponse: Decodable {
    let error: String?
    let messageText: String?
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case error
        case messageText = "message"
        case errorDescription = "error_description"
    }

    var message: String {
        messageText ?? errorDescription ?? error ?? "Unknown error"
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case http(Int, String)
    case server(Int, String)
    case decoding(Error)
    case unauthenticated

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server."
        case .http(let code, _): return "HTTP \(code)"
        case .server(_, let msg): return msg
        case .decoding(let err): return "Decoding error: \(err.localizedDescription)"
        case .unauthenticated: return "Not signed in."
        }
    }
}

extension JSONDecoder.DateDecodingStrategy {
    static var iso8601WithFractionalSeconds: JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = ISO8601Helpers.parse(raw) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(raw)")
        }
    }
}

extension JSONEncoder.DateEncodingStrategy {
    static var iso8601WithFractionalSeconds: JSONEncoder.DateEncodingStrategy {
        .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(ISO8601Helpers.format(date))
        }
    }
}

enum ISO8601Helpers {
    static let fractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    static let plain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func parse(_ string: String) -> Date? {
        fractional.date(from: string) ?? plain.date(from: string)
    }

    static func format(_ date: Date) -> String {
        fractional.string(from: date)
    }
}

