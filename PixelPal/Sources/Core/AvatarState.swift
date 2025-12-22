import Foundation

enum AvatarState: String, Codable {
    case vital
    case neutral
    case lowEnergy
    
    var description: String {
        switch self {
        case .vital: return "Vital"
        case .neutral: return "Neutral"
        case .lowEnergy: return "Low Energy"
        }
    }
}

struct AvatarLogic {
    /// Determines the avatar state based on current steps vs baseline and time of day.
    /// - Parameters:
    ///   - currentSteps: Steps taken today.
    ///   - baselineSteps: Average daily steps (e.g., last 7 days).
    ///   - date: Current date/time.
    /// - Returns: Calculated AvatarState.
    static func determineState(currentSteps: Double, baselineSteps: Double, date: Date = Date()) -> AvatarState {
        // If baseline is 0 (new user), assume a default target, e.g., 5000
        let effectiveBaseline = baselineSteps > 0 ? baselineSteps : 5000.0
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        // Simple pacing logic:
        // By hour X, you should ideally have (X/16) * baseline steps (assuming active hours 7am-11pm)
        // We'll be more lenient.
        
        // Early morning (before 8am): Neutral unless already active
        if hour < 8 {
            return currentSteps > 100 ? .vital : .neutral
        }
        
        // Calculate expected progress
        // Active day assumed 8am to 8pm (12 hours) for simplicity in MVP
        let activeHoursPassed = Double(max(0, min(12, hour - 8)))
        let expectedRatio = activeHoursPassed / 12.0
        let expectedSteps = effectiveBaseline * expectedRatio
        
        // Thresholds
        // If > 110% of expected -> Vital
        // If > 70% of expected -> Neutral
        // Else -> Low Energy
        
        if currentSteps >= (expectedSteps * 1.1) {
            return .vital
        } else if currentSteps >= (expectedSteps * 0.7) {
            return .neutral
        } else {
            return .lowEnergy
        }
    }
}
