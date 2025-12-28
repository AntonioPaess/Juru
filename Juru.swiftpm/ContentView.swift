import SwiftUI

struct ContentView: View {
    @Environment(FaceTrackingManager.self) var faceManager
    @Environment(VocabularyManager.self) var vocabManager
    
    var body: some View {
        // Simplesmente chama a View Principal que cuida de tudo
        MainTypingView(
            vocabManager: vocabManager,
            faceManager: faceManager
        )
    }
}

#Preview {
    let faceManager = FaceTrackingManager()
    ContentView()
        .environment(VocabularyManager(faceManager: faceManager))
        .environment(faceManager)
}
