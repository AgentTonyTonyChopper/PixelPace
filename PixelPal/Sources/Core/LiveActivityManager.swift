import ActivityKit
import Foundation

/// Manages the Pixel Pal Live Activity lifecycle.
@MainActor
class LiveActivityManager: ObservableObject {
    /// Whether a Live Activity is currently running.
    @Published var isActive: Bool = false

    /// The current Live Activity instance.
    private var currentActivity: Activity<PixelPalAttributes>?

    /// Previous step count to detect walking.
    private var previousSteps: Int = 0

    /// Current walking animation frame (1-8).
    private var currentWalkingFrame: Int = 1

    /// Timer for walking animation updates.
    private var walkingTimer: Timer?

    /// Whether currently in walking state.
    private var isWalking: Bool = false

    /// Current gender for updates.
    private var currentGender: Gender = .male

    /// Current avatar state for updates.
    private var currentState: AvatarState = .low

    init() {
        // Check for any existing activities on launch
        checkForExistingActivity()
    }

    /// Checks if there's an existing Live Activity and restores reference to it.
    private func checkForExistingActivity() {
        if let existing = Activity<PixelPalAttributes>.activities.first {
            self.currentActivity = existing
            self.isActive = true
        }
    }

    /// Starts a new Live Activity with the given state.
    /// - Parameters:
    ///   - steps: Current step count.
    ///   - state: Current avatar state.
    ///   - gender: Selected gender.
    func startActivity(steps: Int, state: AvatarState, gender: Gender) {
        // Check if Live Activities are supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        // End any existing activity first
        if currentActivity != nil {
            endActivity()
        }

        let attributes = PixelPalAttributes()
        let contentState = PixelPalAttributes.ContentState(
            steps: steps,
            state: state,
            gender: gender
        )

        do {
            let activity = try Activity<PixelPalAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil // No push updates for v1
            )
            self.currentActivity = activity
            self.isActive = true
            print("Started Live Activity: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    /// Updates the Live Activity with new state.
    /// - Parameters:
    ///   - steps: Current step count.
    ///   - state: Current avatar state.
    ///   - gender: Selected gender.
    func updateActivity(steps: Int, state: AvatarState, gender: Gender) {
        guard let activity = currentActivity else {
            // No active activity, start one instead
            startActivity(steps: steps, state: state, gender: gender)
            return
        }

        // Store current values for timer updates
        currentGender = gender
        currentState = state

        // Detect if user is walking (steps increased)
        let stepsIncreased = steps > previousSteps
        previousSteps = steps

        if stepsIncreased && !isWalking {
            // Start walking animation
            startWalkingAnimation(steps: steps)
        } else if !stepsIncreased && isWalking {
            // Stop walking animation after a delay
            stopWalkingAnimation(steps: steps)
        } else if !isWalking {
            // Normal update (not walking)
            let contentState = PixelPalAttributes.ContentState(
                steps: steps,
                state: state,
                gender: gender,
                isWalking: false,
                walkingFrame: 1
            )

            Task {
                await activity.update(
                    ActivityContent(state: contentState, staleDate: nil)
                )
            }
        }
    }

    /// Starts the walking animation timer.
    private func startWalkingAnimation(steps: Int) {
        isWalking = true
        currentWalkingFrame = 1

        // Update immediately with walking state
        updateWalkingFrame(steps: steps)

        // Start timer to cycle through frames
        walkingTimer?.invalidate()
        walkingTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advanceWalkingFrame(steps: steps)
            }
        }
    }

    /// Advances to the next walking frame.
    private func advanceWalkingFrame(steps: Int) {
        currentWalkingFrame = (currentWalkingFrame % 8) + 1
        updateWalkingFrame(steps: steps)
    }

    /// Updates the Live Activity with current walking frame.
    private func updateWalkingFrame(steps: Int) {
        guard let activity = currentActivity else { return }

        let contentState = PixelPalAttributes.ContentState(
            steps: steps,
            state: currentState,
            gender: currentGender,
            isWalking: true,
            walkingFrame: currentWalkingFrame
        )

        Task {
            await activity.update(
                ActivityContent(state: contentState, staleDate: nil)
            )
        }
    }

    /// Stops the walking animation.
    private func stopWalkingAnimation(steps: Int) {
        walkingTimer?.invalidate()
        walkingTimer = nil
        isWalking = false

        guard let activity = currentActivity else { return }

        let contentState = PixelPalAttributes.ContentState(
            steps: steps,
            state: currentState,
            gender: currentGender,
            isWalking: false,
            walkingFrame: 1
        )

        Task {
            await activity.update(
                ActivityContent(state: contentState, staleDate: nil)
            )
        }
    }

    /// Ends the current Live Activity.
    func endActivity() {
        // Stop walking animation timer
        walkingTimer?.invalidate()
        walkingTimer = nil
        isWalking = false

        guard let activity = currentActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.currentActivity = nil
            self.isActive = false
            print("Ended Live Activity")
        }
    }

    /// Ends all Pixel Pal Live Activities (cleanup utility).
    func endAllActivities() {
        Task {
            for activity in Activity<PixelPalAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            self.currentActivity = nil
            self.isActive = false
        }
    }
}
