import Foundation

/// Centralized helper for sprite asset naming.
/// Ensures consistent naming across app, widget, and Live Activity.
struct SpriteAssets {
    /// Generates the asset catalog name for a sprite.
    /// - Parameters:
    ///   - gender: The character's gender.
    ///   - state: The current avatar state.
    ///   - frame: The animation frame (1 or 2).
    /// - Returns: Asset name string matching the catalog entry.
    static func spriteName(gender: Gender, state: AvatarState, frame: Int) -> String {
        return "\(gender.rawValue)_\(state.rawValue)_\(frame)"
    }

    /// Generates sprite name from raw string values (for use in extensions).
    /// - Parameters:
    ///   - genderRaw: Raw gender string ("male" or "female").
    ///   - stateRaw: Raw state string ("vital", "neutral", or "low").
    ///   - frame: The animation frame (1 or 2).
    /// - Returns: Asset name string.
    static func spriteName(genderRaw: String, stateRaw: String, frame: Int) -> String {
        return "\(genderRaw)_\(stateRaw)_\(frame)"
    }

    /// Generates the asset catalog name for a walking sprite.
    /// - Parameters:
    ///   - gender: The character's gender.
    ///   - frame: The animation frame (1-8).
    /// - Returns: Asset name string matching the catalog entry.
    static func walkingSpriteName(gender: Gender, frame: Int) -> String {
        let clampedFrame = max(1, min(8, frame))
        return "\(gender.rawValue)_walking_\(clampedFrame)"
    }

    /// Generates walking sprite name from raw string values (for use in extensions).
    /// - Parameters:
    ///   - genderRaw: Raw gender string ("male" or "female").
    ///   - frame: The animation frame (1-8).
    /// - Returns: Asset name string.
    static func walkingSpriteName(genderRaw: String, frame: Int) -> String {
        let clampedFrame = max(1, min(8, frame))
        return "\(genderRaw)_walking_\(clampedFrame)"
    }

    /// Total number of walking animation frames.
    static let walkingFrameCount = 8

    /// All expected asset names for validation.
    static var allAssetNames: [String] {
        var names: [String] = []
        for gender in Gender.allCases {
            for state in [AvatarState.vital, .neutral, .low] {
                for frame in 1...2 {
                    names.append(spriteName(gender: gender, state: state, frame: frame))
                }
            }
            // Walking sprites
            for frame in 1...walkingFrameCount {
                names.append(walkingSpriteName(gender: gender, frame: frame))
            }
        }
        return names
    }
}
