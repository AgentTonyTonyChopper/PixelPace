import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Pixel Pal")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Your ambient walking companion.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                healthManager.requestAuthorization { _ in }
            }) {
                Text("Connect HealthKit")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .background(Color.black)
    }
}
