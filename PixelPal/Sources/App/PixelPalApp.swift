import SwiftUI

@main
struct PixelPalApp: App {
    @StateObject private var healthManager = HealthKitManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthManager)
        }
    }
}
