import SwiftUI

@main
struct MyApp: App {
    @State private var faceManager = FaceTrackingManager()
    @State private var vocabularyManager: VocabularyManager?
    
    var body: some Scene {
        WindowGroup {
            RootView(
                faceManager: faceManager,
                vocabularyManager: $vocabularyManager
            )
        }
    }
}
