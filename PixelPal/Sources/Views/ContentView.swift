import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var avatarState: AvatarState = .neutral
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if !healthManager.isAuthorized {
                OnboardingView()
            } else {
                VStack(spacing: 40) {
                    Spacer()
                    
                    AvatarView(state: avatarState)
                    
                    VStack(spacing: 12) {
                        Text(avatarState.description)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Steps: \(Int(healthManager.currentSteps))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Debug/Sync Button
                    Button(action: {
                        healthManager.fetchData()
                        updateState()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white.opacity(0.5))
                            .padding()
                    }
                }
            }
        }
        .onAppear {
            healthManager.requestAuthorization { success in
                if success {
                    updateState()
                }
            }
        }
        .onChange(of: healthManager.currentSteps) { _ in
            updateState()
        }
    }
    
    func updateState() {
        let newState = AvatarLogic.determineState(
            currentSteps: healthManager.currentSteps,
            baselineSteps: healthManager.baselineSteps
        )
        self.avatarState = newState
        
        // Save to shared container for Widget
        SharedData.saveState(state: newState, steps: healthManager.currentSteps)
    }
}
