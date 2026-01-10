import ActivityKit
import Foundation

/// Attributes for the Pixel Pal Live Activity.
/// Used by both the main app (to start/update) and the widget extension (to render).
struct PixelPalAttributes: ActivityAttributes {
    /// Dynamic content that changes during the Live Activity lifecycle.
    public struct ContentState: Codable, Hashable {
        /// Current step count for today (for display).
        var steps: Int

        /// Raw state string: "vital", "neutral", or "low".
        var stateRaw: String

        /// Raw gender string: "male" or "female".
        var genderRaw: String

        /// Whether the user is currently walking (steps increasing).
        var isWalking: Bool

        /// Current walking animation frame (1-32) when walking.
        var walkingFrame: Int

        // MARK: - v1.1 Phase System

        /// Current evolution phase (1-4).
        var currentPhase: Int

        /// Milestone text to display briefly (e.g., "5k!"), nil when not showing.
        var milestoneText: String?

        /// Whether to show step count (only in expanded or walking state per UI rules).
        var showStepCount: Bool

        /// Convenience initializer from typed values (v1 compatible).
        init(steps: Int, state: AvatarState, gender: Gender, isWalking: Bool = false, walkingFrame: Int = 1) {
            self.steps = steps
            self.stateRaw = state.rawValue
            self.genderRaw = gender.rawValue
            self.isWalking = isWalking
            self.walkingFrame = walkingFrame
            self.currentPhase = 1
            self.milestoneText = nil
            self.showStepCount = isWalking  // Only show during walking by default
        }

        /// Full initializer with phase info (v1.1).
        init(
            steps: Int,
            state: AvatarState,
            gender: Gender,
            isWalking: Bool = false,
            walkingFrame: Int = 1,
            currentPhase: Int,
            milestoneText: String? = nil,
            showStepCount: Bool? = nil
        ) {
            self.steps = steps
            self.stateRaw = state.rawValue
            self.genderRaw = gender.rawValue
            self.isWalking = isWalking
            self.walkingFrame = walkingFrame
            self.currentPhase = currentPhase
            self.milestoneText = milestoneText
            // Show step count if walking or if explicitly requested
            self.showStepCount = showStepCount ?? isWalking
        }

        /// Convenience accessor for state enum.
        var state: AvatarState {
            return AvatarState(rawValue: stateRaw) ?? .low
        }

        /// Convenience accessor for gender enum.
        var gender: Gender {
            return Gender(rawValue: genderRaw) ?? .male
        }

        /// Phase name for display.
        var phaseName: String {
            switch currentPhase {
            case 1: return "Dormant"
            case 2: return "Active"
            case 3: return "Energized"
            case 4: return "Ascended"
            default: return "Unknown"
            }
        }

        /// Whether a milestone is being celebrated.
        var isCelebratingMilestone: Bool {
            milestoneText != nil
        }
    }

    // No static attributes needed for v1.
    // The activity content is fully dynamic based on ContentState.
}
