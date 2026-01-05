import ActivityKit
import Foundation

/// Attributes for the Pixel Pal Live Activity.
/// Used by both the main app (to start/update) and the widget extension (to render).
struct PixelPalAttributes: ActivityAttributes {
    /// Dynamic content that changes during the Live Activity lifecycle.
    public struct ContentState: Codable, Hashable {
        /// Current step count for today.
        var steps: Int

        /// Raw state string: "vital", "neutral", or "low".
        var stateRaw: String

        /// Raw gender string: "male" or "female".
        var genderRaw: String

        /// Whether the user is currently walking (steps increasing).
        var isWalking: Bool

        /// Current walking animation frame (1-8) when walking.
        var walkingFrame: Int

        /// Convenience initializer from typed values.
        init(steps: Int, state: AvatarState, gender: Gender, isWalking: Bool = false, walkingFrame: Int = 1) {
            self.steps = steps
            self.stateRaw = state.rawValue
            self.genderRaw = gender.rawValue
            self.isWalking = isWalking
            self.walkingFrame = walkingFrame
        }

        /// Convenience accessor for state enum.
        var state: AvatarState {
            return AvatarState(rawValue: stateRaw) ?? .low
        }

        /// Convenience accessor for gender enum.
        var gender: Gender {
            return Gender(rawValue: genderRaw) ?? .male
        }
    }

    // No static attributes needed for v1.
    // The activity content is fully dynamic based on ContentState.
}
