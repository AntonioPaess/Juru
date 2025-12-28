import SwiftUI

struct ContentView: View {
    @Environment(FaceTrackingManager.self) var faceManager
    @Environment(VocabularyManager.self) var vocabManager
    
    var body: some View {
        ZStack {
            CalibrationView(manager: faceManager)
            VStack {
                Text("Message: \(vocabManager.currentMessage)")
                    .font(.largeTitle)
                    .padding()
                    .background(.ultraThinMaterial)
                Spacer()
            }
        }
        .onChange(of: faceManager.smileRight) { vocabManager.update() }
        .onChange(of: faceManager.smileLeft) { vocabManager.update() }
        .onChange(of: faceManager.mouthPucker) { vocabManager.update() }
    }
}

#Preview {
    let face = FaceTrackingManager()
    let vocab = VocabularyManager(faceManager: face)
    
    return ContentView()
        .environment(face)
        .environment(vocab)
}
