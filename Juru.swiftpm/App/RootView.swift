import SwiftUI

struct RootView: View {
    var faceManager: FaceTrackingManager
    @Binding var vocabularyManager: VocabularyManager?
    
    @Environment(\.scenePhase) var scenePhase
    
    enum AppFlow {
        case loading
        case permissionDenied
        case calibration
        case mainApp
    }
    @State private var currentFlow: AppFlow = .loading
    
    var body: some View {
        ZStack {
            switch currentFlow {
            case .loading:
                JuruLoadingView()
                    .onAppear { handleLoadingSequence() }
                
            case .permissionDenied:
                PermissionDeniedView()
                
            case .calibration:
                CalibrationView(
                    faceManager: faceManager,
                    onCalibrationComplete: {
                        withAnimation { currentFlow = .mainApp }
                    }
                )
                
            case .mainApp:
                if let vocab = vocabularyManager {
                    MainTypingView(vocabManager: vocab, faceManager: faceManager)
                } else {
                    ContentUnavailableView(
                        "Vocabulary Error",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Could not load language data.")
                    )
                }
            }
        }
        .animation(.easeInOut, value: currentFlow)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                faceManager.pause()
            } else if newPhase == .active && currentFlow == .mainApp {
                if let session = faceManager.currentSession {
                    faceManager.start(session: session)
                }
            }
        }
        .onChange(of: faceManager.isCameraDenied) { _, denied in
            if denied { currentFlow = .permissionDenied }
        }
    }
    
    private func handleLoadingSequence() {
        if vocabularyManager == nil {
            vocabularyManager = VocabularyManager(faceManager: faceManager)
        }
        
        Task {
            // Mantém o loading visível por um tempo mínimo para branding
            try? await Task.sleep(for: .seconds(1.5))
            await checkPrerequisites()
        }
    }
    
    private func checkPrerequisites() async {
        if faceManager.isCameraDenied {
            currentFlow = .permissionDenied
            return
        }

        if faceManager.hasSavedCalibration {
            // O prompt nativo do iOS aparecerá sobre o JuruLoadingView
            let result = await BiometricAuth.authenticate()
            
            switch result {
            case .success(true):
                withAnimation { currentFlow = .mainApp }
            case .success(false), .failure:
                // Se falhar ou cancelar, cai suavemente para a calibração
                withAnimation { currentFlow = .calibration }
            }
        } else {
            withAnimation { currentFlow = .calibration }
        }
    }
}
