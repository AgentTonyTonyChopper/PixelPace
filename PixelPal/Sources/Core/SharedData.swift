import Foundation
import WidgetKit

struct SharedData {
    static let appGroupId = "group.com.pixelpalfit.app"
    
    struct Keys {
        static let avatarState = "avatarState"
        static let lastUpdateDate = "lastUpdateDate"
        static let currentSteps = "currentSteps"
    }
    
    static var userDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupId)
    }
    
    static func saveState(state: AvatarState, steps: Double) {
        guard let defaults = userDefaults else { return }
        defaults.set(state.rawValue, forKey: Keys.avatarState)
        defaults.set(steps, forKey: Keys.currentSteps)
        defaults.set(Date(), forKey: Keys.lastUpdateDate)
        
        // Reload widget
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    static func loadState() -> AvatarState {
        guard let defaults = userDefaults,
              let rawValue = defaults.string(forKey: Keys.avatarState),
              let state = AvatarState(rawValue: rawValue) else {
            return .neutral // Default
        }
        return state
    }
    
    static func loadSteps() -> Double {
        guard let defaults = userDefaults else { return 0 }
        return defaults.double(forKey: Keys.currentSteps)
    }
}
