import SwiftUI

@main
struct MyApp: App {
    @State private var faceManager = FaceTrackingManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(faceManager)
        }
    }
}
