import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @StateObject private var liveActivityManager = LiveActivityManager()
    @StateObject private var storeManager = StoreManager.shared

    @State private var avatarState: AvatarState = .low
    @State private var gender: Gender = .male
    @State private var showPaywall: Bool = false

    // Phase tracking
    @State private var currentPhase: Int = 1
    @State private var cumulativeSteps: Int = 0
    @State private var previousPhase: Int = 1

    /// Whether onboarding is complete (UserProfile exists + HealthKit authorized).
    private var isOnboardingComplete: Bool {
        let profile = PersistenceManager.shared.userProfile
        return profile != nil && healthManager.isAuthorized
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
                fetchCumulativeSteps()
            }
        }
        .onChange(of: healthManager.currentSteps) { _ in
            updateState()
        }
        .onChange(of: healthManager.cumulativeSteps) { newCumulative in
            updatePhase(cumulativeSteps: newCumulative)
        }
        .onChange(of: healthManager.isAuthorized) { authorized in
            if authorized {
                // Reload saved data (including gender) after onboarding completes
                loadSavedData()
                healthManager.fetchData()
                fetchCumulativeSteps()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(storeManager: storeManager, gender: gender)
        }
    }

    // MARK: - Main Content

    private var mainContentView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Phase indicator
            PhaseDisplayView(phase: currentPhase, isPremium: storeManager.isPremium)

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

                // Cumulative steps (evolution progress)
                Text("\(cumulativeSteps.formatted()) total steps")
                    .font(.caption)
                    .foregroundColor(phaseColor.opacity(0.8))

                // Phase progress
                PhaseProgressView(
                    currentSteps: cumulativeSteps,
                    currentPhase: currentPhase,
                    isPremium: storeManager.isPremium
                )
                .padding(.top, 8)

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
                fetchCumulativeSteps()
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

    // MARK: - Phase Color

    private var phaseColor: Color {
        switch currentPhase {
        case 1: return .gray
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        default: return .gray
        }
    }

    // MARK: - Live Activity Controls

    private var liveActivityControls: some View {
        VStack(spacing: 12) {
            if liveActivityManager.isActive {
                Button(action: {
                    liveActivityManager.endActivity()
                }) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("Stop Pixel Pace")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                Text("Live Activity is running")
                    .font(.caption)
                    .foregroundColor(.green.opacity(0.8))
            } else {
                Button(action: {
                    liveActivityManager.startActivity(
                        steps: Int(healthManager.currentSteps),
                        state: avatarState,
                        gender: gender,
                        phase: currentPhase
                    )
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Start Pixel Pace")
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

            // Debug: Test Paywall (remove before App Store submission)
            #if DEBUG
            Button(action: { showPaywall = true }) {
                Text("Test Paywall")
                    .font(.caption2)
                    .foregroundColor(.purple.opacity(0.6))
            }
            #endif
        }
    }

    // MARK: - State Management

    private func loadSavedData() {
        // Load gender from UserProfile
        if let profile = PersistenceManager.shared.userProfile {
            gender = profile.selectedGender
        } else if let savedGender = SharedData.loadGender() {
            // Fallback to legacy SharedData
            gender = savedGender
        }

        // Load progress state
        let progress = PersistenceManager.shared.progressState
        currentPhase = progress.currentPhase
        previousPhase = progress.currentPhase
        cumulativeSteps = progress.totalStepsSinceStart

        avatarState = SharedData.loadState()
    }

    private func fetchCumulativeSteps() {
        guard let profile = PersistenceManager.shared.userProfile else { return }

        Task {
            await healthManager.fetchCumulativeStepsAsync(since: profile.createdAt)
            await MainActor.run {
                cumulativeSteps = healthManager.cumulativeSteps
                updatePhase(cumulativeSteps: cumulativeSteps)
            }
        }
    }

    private func updatePhase(cumulativeSteps: Int) {
        self.cumulativeSteps = cumulativeSteps

        let entitlements = PersistenceManager.shared.entitlements
        let newPhase = PhaseCalculator.currentPhase(
            totalSteps: cumulativeSteps,
            isPremium: entitlements.isPremium
        )

        // Check for phase up (evolution)
        if newPhase > currentPhase {
            currentPhase = newPhase

            // Save progress
            PersistenceManager.shared.updateProgress { progress in
                progress.totalStepsSinceStart = cumulativeSteps
                progress.currentPhase = newPhase
            }

            // Check if we should show paywall (Phase 2 reached, not premium, not seen before)
            if newPhase == 2 && !entitlements.isPremium {
                let progress = PersistenceManager.shared.progressState
                if !progress.hasSeenPaywall {
                    showPaywall = true
                    PersistenceManager.shared.updateProgress { progress in
                        progress.hasSeenPaywall = true
                    }
                }
            }
        } else {
            currentPhase = newPhase
        }
    }

    private func updateState() {
        let newState = AvatarLogic.determineState(steps: healthManager.currentSteps)
        self.avatarState = newState

        // Save to shared container for Widget
        SharedData.saveState(state: newState, steps: healthManager.currentSteps, phase: currentPhase)

        // Update progress with today's steps
        PersistenceManager.shared.updateProgress { progress in
            progress.todaySteps = Int(healthManager.currentSteps)
            progress.totalStepsSinceStart = cumulativeSteps
        }

        // Update Live Activity if active
        if liveActivityManager.isActive {
            liveActivityManager.updateActivity(
                steps: Int(healthManager.currentSteps),
                state: newState,
                gender: gender,
                phase: currentPhase,
                cumulativeSteps: cumulativeSteps
            )
        }
    }
}

// MARK: - Phase Display View

private struct PhaseDisplayView: View {
    let phase: Int
    let isPremium: Bool

    private var phaseColor: Color {
        switch phase {
        case 1: return .gray
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        default: return .gray
        }
    }

    private var phaseIcon: String {
        switch phase {
        case 1: return "circle"
        case 2: return "circle.fill"
        case 3: return "star.fill"
        case 4: return "sparkles"
        default: return "circle"
        }
    }

    private var phaseName: String {
        switch phase {
        case 1: return "Seedling"
        case 2: return "Growing"
        case 3: return "Thriving"
        case 4: return "Legendary"
        default: return "Unknown"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: phaseIcon)
                .font(.title3)
                .foregroundColor(phaseColor)

            Text("Phase \(phase)")
                .font(.headline)
                .foregroundColor(.white)

            Text("• \(phaseName)")
                .font(.subheadline)
                .foregroundColor(phaseColor)

            if isPremium {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(phaseColor.opacity(0.2))
        .cornerRadius(20)
    }
}

// MARK: - Phase Progress View

private struct PhaseProgressView: View {
    let currentSteps: Int
    let currentPhase: Int
    let isPremium: Bool

    private var nextThreshold: Int {
        PhaseCalculator.nextThreshold(for: currentPhase)
    }

    private var currentThreshold: Int {
        switch currentPhase {
        case 1: return 0
        case 2: return PhaseCalculator.phase2Threshold
        case 3: return PhaseCalculator.phase3Threshold
        case 4: return PhaseCalculator.phase4Threshold
        default: return 0
        }
    }

    private var progress: Double {
        guard nextThreshold > currentThreshold else { return 1.0 }
        let stepsInPhase = currentSteps - currentThreshold
        let phaseRange = nextThreshold - currentThreshold
        return min(1.0, Double(stepsInPhase) / Double(phaseRange))
    }

    private var stepsToNext: Int {
        max(0, nextThreshold - currentSteps)
    }

    var body: some View {
        VStack(spacing: 4) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 40)

            // Progress text
            if currentPhase < 4 {
                if currentPhase >= 2 && !isPremium {
                    Text("Unlock Premium for Phase \(currentPhase + 1)")
                        .font(.caption2)
                        .foregroundColor(.purple.opacity(0.8))
                } else {
                    Text("\(stepsToNext.formatted()) steps to Phase \(currentPhase + 1)")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.8))
                }
            } else {
                Text("Maximum evolution reached!")
                    .font(.caption2)
                    .foregroundColor(.orange.opacity(0.8))
            }
        }
    }

    private var progressColor: Color {
        switch currentPhase {
        case 1: return .gray
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        default: return .gray
        }
    }
}
