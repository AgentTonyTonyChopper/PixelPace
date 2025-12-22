import SwiftUI

struct AvatarView: View {
    let state: AvatarState
    @State private var frameIndex = 0
    
    // Timer for breathing animation (approx 1 second per frame for slow breathing)
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Image(uiImage: imageForState(state, frame: frameIndex))
            .resizable()
            .interpolation(.none) // Pixel art style
            .aspectRatio(contentMode: .fit)
            .frame(width: 200, height: 200)
            .onReceive(timer) { _ in
                frameIndex = (frameIndex + 1) % 2
            }
            .animation(.easeInOut(duration: 0.5), value: frameIndex) // Subtle transition
    }
    
    func imageForState(_ state: AvatarState, frame: Int) -> UIImage {
        let name: String
        switch state {
        case .vital: name = "vital_\(frame + 1)"
        case .neutral: name = "neutral_\(frame + 1)"
        case .lowEnergy: name = "low_\(frame + 1)"
        }
        
        // Load from RawAssets for MVP since we didn't compile Assets.xcassets
        // In a real app, use Image(name)
        // Here we load from file path for the user to see it works if they run it in simulator with files added,
        // but actually, UIImage(named:) requires assets in the bundle.
        // Since I can't easily put them in the bundle without Xcode, I will assume the user adds them.
        // BUT, for the code to be valid Swift for the user to copy, I should use `UIImage(named: name)`.
        // I will add a helper to load from disk if bundle fails, just for testing? No, keep it clean.
        // I will assume the user adds the assets.
        
        return UIImage(named: name) ?? UIImage()
    }
}
