import Foundation

/// User profile data persisted on device.
/// Created during onboarding and used as baseline for cumulative step tracking.
struct UserProfile: Codable, Equatable {
    /// Selected character gender.
    var selectedGender: Gender

    /// Selected starter style/appearance.
    var selectedStarterStyle: String

    /// Date when the user completed onboarding.
    /// Used as baseline for cumulative step calculation.
    var createdAt: Date

    /// Whether onboarding has been completed.
    var hasCompletedOnboarding: Bool

    /// Creates a new user profile with default values.
    static func createNew(gender: Gender, starterStyle: String = "default") -> UserProfile {
        UserProfile(
            selectedGender: gender,
            selectedStarterStyle: starterStyle,
            createdAt: Date(),
            hasCompletedOnboarding: true
        )
    }
}
