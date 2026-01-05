import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @StateObject private var liveActivityManager = LiveActivityManager()

    @State private var avatarState: AvatarState = .low
    @State private var gender: Gender = .male
    @State private var isDemoWalking: Bool = false
    @State private var demoSteps: Int = 0

    /// Whether onboarding is complete (gender selected + HealthKit authorized).
    private var isOnboardingComplete: Bool {
        return SharedData.hasSelectedGender && healthManager.isAuthorized
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            if !isOnboardingComplete {
                OnboardingView()
            } else {
                mainContentView
            }
        }
        .onAppear {
            loadSavedData()
            if healthManager.isAuthorized {
                healthManager.fetchData()
            }
        }
        .onChange(of: healthManager.currentSteps) { _ in
            updateState()
        }
        .onChange(of: healthManager.isAuthorized) { authorized in
            if authorized {
                healthManager.fetchData()
            }
        }
    }

    // MARK: - Main Content

    private var mainContentView: some View {
        VStack(spacing: 30) {
            Spacer()

            // Avatar
            AvatarView(state: avatarState, gender: gender)

            // State & Steps
            VStack(spacing: 8) {
                Text(avatarState.description)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))

                Text("\(Int(healthManager.currentSteps)) steps today")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                if let lastUpdate = SharedData.loadLastUpdateDate() {
                    Text("Updated \(lastUpdate.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.6))
                }
            }

            Spacer()

            // Live Activity Controls
            liveActivityControls

            // Refresh Button
            Button(action: {
                healthManager.fetchData()
                updateState()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .padding(.vertical, 8)
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Live Activity Controls

    private var liveActivityControls: some View {
        VStack(spacing: 12) {
            if liveActivityManager.isActive {
                Button(action: {
                    liveActivityManager.endActivity()
                    stopDemoWalking()
                }) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("Stop Pixel Pal")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                // Demo Walking Button
                Button(action: {
                    if isDemoWalking {
                        stopDemoWalking()
                    } else {
                        startDemoWalking()
                    }
                }) {
                    HStack {
                        Image(systemName: isDemoWalking ? "figure.stand" : "figure.walk")
                        Text(isDemoWalking ? "Stop Demo" : "Demo Walking")
                    }
                    .font(.subheadline)
                    .foregroundColor(isDemoWalking ? .black : .white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(isDemoWalking ? Color.yellow : Color.blue.opacity(0.8))
                    .cornerRadius(8)
                }

                Text(isDemoWalking ? "Walking animation active!" : "Live Activity is running")
                    .font(.caption)
                    .foregroundColor(isDemoWalking ? .yellow : .green.opacity(0.8))
            } else {
                Button(action: {
                    liveActivityManager.startActivity(
                        steps: Int(healthManager.currentSteps),
                        state: avatarState,
                        gender: gender
                    )
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Start Pixel Pal")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                Text("Show on Lock Screen & Dynamic Island")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - State Management

    private func loadSavedData() {
        if let savedGender = SharedData.loadGender() {
            gender = savedGender
        }
        avatarState = SharedData.loadState()
    }

    private func updateState() {
        let newState = AvatarLogic.determineState(steps: healthManager.currentSteps)
        self.avatarState = newState

        // Save to shared container for Widget
        SharedData.saveState(state: newState, steps: healthManager.currentSteps)

        // Update Live Activity if active (but not during demo)
        if liveActivityManager.isActive && !isDemoWalking {
            liveActivityManager.updateActivity(
                steps: Int(healthManager.currentSteps),
                state: newState,
                gender: gender
            )
        }
    }

    // MARK: - Demo Walking

    private func startDemoWalking() {
        isDemoWalking = true
        demoSteps = Int(healthManager.currentSteps)

        // Start simulating step increases to trigger walking animation
        simulateWalking()
    }

    private func stopDemoWalking() {
        isDemoWalking = false
        // Update with actual steps to stop walking animation
        if liveActivityManager.isActive {
            liveActivityManager.updateActivity(
                steps: Int(healthManager.currentSteps),
                state: avatarState,
                gender: gender
            )
        }
    }

    private func simulateWalking() {
        guard isDemoWalking else { return }

        // Increment demo steps to trigger walking detection
        demoSteps += 1

        // Update live activity with incremented steps
        liveActivityManager.updateActivity(
            steps: demoSteps,
            state: avatarState,
            gender: gender
        )

        // Continue simulating after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            simulateWalking()
        }
    }
}
