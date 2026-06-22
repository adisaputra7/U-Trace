import Foundation

/// Copy this file to InsforgeConfig.swift and fill in your own values.
/// InsforgeConfig.swift is git-ignored and must never be committed.
///
/// Get these values from your Insforge project dashboard:
///   https://insforge.app → your project → Settings → API
enum InsforgeConfig {
    static let baseURLString = "https://YOUR_PROJECT_ID.REGION.insforge.app"
    static let anonKey       = "YOUR_ANON_KEY_HERE"

    static var baseURL: URL { URL(string: baseURLString)! }
}
