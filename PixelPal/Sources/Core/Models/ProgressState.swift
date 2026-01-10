import Foundation

/// Tracks user's cumulative progress and evolution phase.
/// Evolution is permanent - phases never reset or reverse.
struct ProgressState: Codable, Equatable {
    /// Total steps accumulated since UserProfile.createdAt.
    /// This drives phase evolution and never resets.
    var totalStepsSinceStart: Int

    /// Last time HealthKit data was synced.
    var lastHealthKitSync: Date?

    /// Current evolution phase (1-4).
    /// Phase 1: Dormant (0-25,000 steps)
    /// Phase 2: Active (25,001-75,000 steps)
    /// Phase 3: Energized (75,001-200,000 steps) - Premium
    /// Phase 4: Ascended (200,001+ steps) - Premium
    var currentPhase: Int

    /// Whether the user has seen the paywall (shown after Phase 2 unlock).
    var hasSeenPaywall: Bool

    /// Today's step count (for display, separate from cumulative).
    var todaySteps: Int

    /// Creates initial progress state for a new user.
    static func createNew() -> ProgressState {
        ProgressState(
            totalStepsSinceStart: 0,
            lastHealthKitSync: nil,
            currentPhase: 1,
            hasSeenPaywall: false,
            todaySteps: 0
        )
    }

    /// Updates the phase based on total steps and premium status.
    mutating func updatePhase(isPremium: Bool) {
        let newPhase = PhaseCalculator.currentPhase(
            totalSteps: totalStepsSinceStart,
            isPremium: isPremium
        )
        // Phase can only increase, never decrease
        if newPhase > currentPhase {
            currentPhase = newPhase
        }
    }
}
