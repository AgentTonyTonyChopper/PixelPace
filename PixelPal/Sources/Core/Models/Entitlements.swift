import Foundation

/// Tracks premium subscription status.
struct Entitlements: Codable, Equatable {
    /// Whether the user has an active premium subscription.
    var isPremium: Bool

    /// Date when premium was first activated.
    var premiumSince: Date?

    /// Creates default free tier entitlements.
    static func createFree() -> Entitlements {
        Entitlements(isPremium: false, premiumSince: nil)
    }

    /// Creates premium entitlements.
    static func createPremium() -> Entitlements {
        Entitlements(isPremium: true, premiumSince: Date())
    }

    /// Activates premium subscription.
    mutating func activatePremium() {
        isPremium = true
        if premiumSince == nil {
            premiumSince = Date()
        }
    }

    /// Deactivates premium subscription (e.g., subscription expired).
    mutating func deactivatePremium() {
        isPremium = false
        // Keep premiumSince for historical record
    }
}
