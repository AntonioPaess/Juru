import SwiftUI

struct ContentView: View {
    @Environment(FaceTrackingManager.self) var faceManager
    @Environment(VocabularyManager.self) var vocabManager
    
    var body: some View {
        MainTypingView(
            vocabManager: vocabManager,
            faceManager: faceManager
        )
    }
}

