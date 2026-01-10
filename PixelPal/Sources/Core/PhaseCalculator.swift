import Foundation

/// Calculates evolution phase based on cumulative steps.
/// Evolution is permanent - phases never reset or reverse.
struct PhaseCalculator {
    /// Phase thresholds (cumulative steps).
    static let phase1Max = 25_000
    static let phase2Max = 75_000
    static let phase3Max = 200_000

    // Threshold aliases for ContentView compatibility
    static let phase2Threshold = phase1Max
    static let phase3Threshold = phase2Max
    static let phase4Threshold = phase3Max

    /// Returns the step threshold for the next phase.
    static func nextThreshold(for phase: Int) -> Int {
        switch phase {
        case 1: return phase1Max
        case 2: return phase2Max
        case 3: return phase3Max
        default: return phase3Max
        }
    }

    /// Phase names for display.
    static let phaseNames = [
        1: "Dormant",
        2: "Active",
        3: "Energized",
        4: "Ascended"
    ]

    /// Phase descriptions for UI.
    static let phaseDescriptions = [
        1: "This is the beginning.",
        2: "Movement is becoming part of you.",
        3: "This is momentum.",
        4: "You've changed."
    ]

    /// Calculates the current phase based on total steps and premium status.
    /// - Parameters:
    ///   - totalSteps: Cumulative steps since app creation.
    ///   - isPremium: Whether the user has premium subscription.
    /// - Returns: Phase number (1-4). Non-premium users are capped at Phase 2.
    static func currentPhase(totalSteps: Int, isPremium: Bool) -> Int {
        switch totalSteps {
        case 0...phase1Max:
            return 1
        case (phase1Max + 1)...phase2Max:
            return 2
        case (phase2Max + 1)...phase3Max:
            return isPremium ? 3 : 2
        default:
            return isPremium ? 4 : 2
        }
    }

    /// Returns the accessible phase (considering premium status).
    /// - Parameters:
    ///   - totalSteps: Cumulative steps since app creation.
    ///   - isPremium: Whether the user has premium subscription.
    /// - Returns: The highest phase the user can access.
    static func accessiblePhase(totalSteps: Int, isPremium: Bool) -> Int {
        return currentPhase(totalSteps: totalSteps, isPremium: isPremium)
    }

    /// Returns the earned phase (ignoring premium status).
    /// Used to determine if paywall should be shown.
    /// - Parameter totalSteps: Cumulative steps since app creation.
    /// - Returns: Phase number based purely on steps (1-4).
    static func earnedPhase(totalSteps: Int) -> Int {
        switch totalSteps {
        case 0...phase1Max:
            return 1
        case (phase1Max + 1)...phase2Max:
            return 2
        case (phase2Max + 1)...phase3Max:
            return 3
        default:
            return 4
        }
    }

    /// Returns progress percentage within current phase.
    /// - Parameter totalSteps: Cumulative steps since app creation.
    /// - Returns: Progress percentage (0.0 to 1.0).
    static func progressInPhase(totalSteps: Int) -> Double {
        let earned = earnedPhase(totalSteps: totalSteps)

        switch earned {
        case 1:
            return Double(totalSteps) / Double(phase1Max)
        case 2:
            let stepsInPhase = totalSteps - phase1Max
            let phaseSize = phase2Max - phase1Max
            return Double(stepsInPhase) / Double(phaseSize)
        case 3:
            let stepsInPhase = totalSteps - phase2Max
            let phaseSize = phase3Max - phase2Max
            return Double(stepsInPhase) / Double(phaseSize)
        default:
            // Phase 4 has no upper limit, show progress toward next 100k
            let stepsInPhase = totalSteps - phase3Max
            let milestone = 100_000
            return Double(stepsInPhase % milestone) / Double(milestone)
        }
    }

    /// Returns steps needed to reach next phase.
    /// - Parameter totalSteps: Cumulative steps since app creation.
    /// - Returns: Steps remaining to next phase, or nil if at Phase 4.
    static func stepsToNextPhase(totalSteps: Int) -> Int? {
        let earned = earnedPhase(totalSteps: totalSteps)

        switch earned {
        case 1:
            return phase1Max - totalSteps + 1
        case 2:
            return phase2Max - totalSteps + 1
        case 3:
            return phase3Max - totalSteps + 1
        default:
            return nil // Phase 4 is the final phase
        }
    }

    /// Checks if a phase transition just occurred.
    /// - Parameters:
    ///   - previousSteps: Previous cumulative step count.
    ///   - currentSteps: Current cumulative step count.
    /// - Returns: The new phase if a transition occurred, nil otherwise.
    static func checkPhaseTransition(previousSteps: Int, currentSteps: Int) -> Int? {
        let previousPhase = earnedPhase(totalSteps: previousSteps)
        let currentPhase = earnedPhase(totalSteps: currentSteps)

        if currentPhase > previousPhase {
            return currentPhase
        }
        return nil
    }

    /// Checks if user should see paywall (earned Phase 3+ but not premium).
    /// - Parameters:
    ///   - totalSteps: Cumulative steps since app creation.
    ///   - isPremium: Whether the user has premium subscription.
    ///   - hasSeenPaywall: Whether user has already seen the paywall.
    /// - Returns: True if paywall should be shown.
    static func shouldShowPaywall(
        totalSteps: Int,
        isPremium: Bool,
        hasSeenPaywall: Bool
    ) -> Bool {
        guard !isPremium && !hasSeenPaywall else { return false }
        let earned = earnedPhase(totalSteps: totalSteps)
        return earned >= 3
    }
}

/// Milestone thresholds for celebration display.
struct MilestoneCalculator {
    /// Common milestone values.
    static let milestones = [1_000, 2_500, 5_000, 7_500, 10_000, 15_000, 20_000, 25_000,
                             50_000, 75_000, 100_000, 150_000, 200_000, 250_000, 500_000, 1_000_000]

    /// Checks if a milestone was just reached.
    /// - Parameters:
    ///   - previousSteps: Previous cumulative step count.
    ///   - currentSteps: Current cumulative step count.
    /// - Returns: The milestone value if one was just crossed, nil otherwise.
    static func checkMilestone(previousSteps: Int, currentSteps: Int) -> Int? {
        for milestone in milestones {
            if previousSteps < milestone && currentSteps >= milestone {
                return milestone
            }
        }
        return nil
    }

    /// Formats a milestone for display (e.g., "5k!", "100k!").
    /// - Parameter milestone: The milestone value.
    /// - Returns: Formatted string for display.
    static func formatMilestone(_ milestone: Int) -> String {
        if milestone >= 1_000_000 {
            return "\(milestone / 1_000_000)M!"
        } else if milestone >= 1_000 {
            return "\(milestone / 1_000)k!"
        } else {
            return "\(milestone)!"
        }
    }
}
