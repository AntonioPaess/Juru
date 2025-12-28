import SwiftUI

@main
struct MyApp: App {
    @State private var faceManager = FaceTrackingManager()
    @State private var vocabularyManager: VocabularyManager?
    var body: some Scene {
        WindowGroup {
            if let vocabManager = vocabularyManager {
                ContentView()
                    .environment(faceManager)
                    .environment(vocabManager)
            } else {
                JuruLoadingView()
                    .onAppear {
                        vocabularyManager = VocabularyManager(faceManager: faceManager)
                    }
            }
        }
    }
}
