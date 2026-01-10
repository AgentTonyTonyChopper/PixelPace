import SwiftUI

/// 5-screen onboarding flow (v1.1 spec).
/// 1. Identity Hook - "Your steps tell a story"
/// 2. Character Selection - Gender + starter style
/// 3. Truth Moment - Step benchmarks
/// 4. Differentiation - "Not another step counter"
/// 5. Permissions - HealthKit request
struct OnboardingView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var currentStep: Int = 1
    @State private var selectedGender: Gender? = nil
    @State private var selectedStyle: String = "default"

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                ProgressIndicator(currentStep: currentStep, totalSteps: 5)
                    .padding(.top, 20)
                    .padding(.horizontal, 40)

                Spacer()

                // Current screen content
                Group {
                    switch currentStep {
                    case 1:
                        IdentityHookScreen(onContinue: { nextStep() })
                    case 2:
                        CharacterSelectionScreen(
                            selectedGender: $selectedGender,
                            selectedStyle: $selectedStyle,
                            onContinue: { nextStep() }
                        )
                    case 3:
                        TruthMomentScreen(onContinue: { nextStep() })
                    case 4:
                        DifferentiationScreen(onContinue: { nextStep() })
                    case 5:
                        PermissionsScreen(
                            selectedGender: selectedGender,
                            selectedStyle: selectedStyle,
                            healthManager: healthManager
                        )
                    default:
                        EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()
            }
        }
    }

    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
    }
}

// MARK: - Progress Indicator

private struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.white : Color.white.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }
}

// MARK: - Screen 1: Identity Hook

private struct IdentityHookScreen: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Animated character preview
            Image("male_neutral_1")
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Text("Your steps tell a story")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("PixelPal turns movement into a living character you see all day.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Mock Dynamic Island preview
            DynamicIslandPreview()
                .padding(.vertical, 20)

            Spacer().frame(height: 40)

            OnboardingButton(title: "Start my PixelPal", action: onContinue)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Screen 2: Character Selection

private struct CharacterSelectionScreen: View {
    @Binding var selectedGender: Gender?
    @Binding var selectedStyle: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Choose your PixelPal")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("This character grows when you move.")
                .font(.body)
                .foregroundColor(.gray)

            // Gender selection
            HStack(spacing: 40) {
                GenderButton(gender: .male, isSelected: selectedGender == .male) {
                    selectedGender = .male
                }
                GenderButton(gender: .female, isSelected: selectedGender == .female) {
                    selectedGender = .female
                }
            }
            .padding(.vertical, 20)

            if selectedGender != nil {
                OnboardingButton(title: "Continue", action: onContinue)
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct GenderButton: View {
    let gender: Gender
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(SpriteAssets.spriteName(gender: gender, state: .neutral, frame: 1))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)

                Text(gender.displayName)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - Screen 3: Truth Moment

private struct TruthMomentScreen: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.walk")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Most people walk less than they think")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                StatRow(label: "Average American", value: "3,000-4,000", unit: "steps/day")
                StatRow(label: "Recommended", value: "7,500-10,000", unit: "steps/day")
                StatRow(label: "Highly active", value: "12,000+", unit: "steps/day")
            }
            .padding(.vertical, 20)

            Text("PixelPal shows the truth in real time.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 20)

            OnboardingButton(title: "Continue", action: onContinue)
        }
        .padding(.horizontal, 24)
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            Text(unit)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Screen 4: Differentiation

private struct DifferentiationScreen: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundColor(.purple)

            Text("This isn't another step counter")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "arrow.up.circle.fill", color: .green,
                           text: "Evolves as you walk")
                FeatureRow(icon: "iphone.badge.play", color: .blue,
                           text: "Lives in Dynamic Island and Lock Screen")
                FeatureRow(icon: "bell.slash.fill", color: .orange,
                           text: "Motivation without notifications")
            }
            .padding(.vertical, 20)

            Spacer().frame(height: 20)

            OnboardingButton(title: "Continue", action: onContinue)
        }
        .padding(.horizontal, 24)
    }
}

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            Text(text)
                .font(.body)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Screen 5: Permissions

private struct PermissionsScreen: View {
    let selectedGender: Gender?
    let selectedStyle: String
    let healthManager: HealthKitManager

    var body: some View {
        VStack(spacing: 24) {
            if let gender = selectedGender {
                Image(SpriteAssets.spriteName(gender: gender, state: .vital, frame: 1))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
            }

            Text("Let PixelPal walk with you")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("We only use steps to evolve your character.\nNo data leaves your device.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // Privacy assurance
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.green)
                Text("100% Private")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .padding(.vertical, 10)

            Spacer().frame(height: 20)

            OnboardingButton(title: "Enable Steps") {
                completeOnboarding()
            }
        }
        .padding(.horizontal, 24)
    }

    private func completeOnboarding() {
        guard let gender = selectedGender else { return }

        // Create user profile
        let profile = UserProfile.createNew(gender: gender, starterStyle: selectedStyle)
        Task { @MainActor in
            PersistenceManager.shared.saveUserProfile(profile)
        }

        // Also save to legacy SharedData for backward compatibility
        SharedData.saveGender(gender)

        // Request HealthKit authorization
        healthManager.requestAuthorization { _ in }
    }
}

// MARK: - Shared Components

private struct OnboardingButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(12)
        }
        .padding(.horizontal, 40)
    }
}

private struct DynamicIslandPreview: View {
    var body: some View {
        // Mock Dynamic Island shape
        HStack(spacing: 12) {
            // Camera cutout
            Circle()
                .fill(Color.black)
                .frame(width: 12, height: 12)

            // Character preview
            Image("male_neutral_1")
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
        )
    }
}
