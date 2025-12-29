import SwiftUI

@main
struct MyApp: App {
    // Estado Global (Source of Truth)
    @State private var faceManager = FaceTrackingManager()
    @State private var vocabularyManager: VocabularyManager?
    
    // Controle de Fluxo
    enum AppFlow {
        case loading
        case calibration
        case mainApp
    }
    @State private var currentFlow: AppFlow = .loading
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch currentFlow {
                case .loading:
                    JuruLoadingView()
                        .onAppear {
                            // 1. Inicializa dependências
                            vocabularyManager = VocabularyManager(faceManager: faceManager)
                            faceManager.start()
                            
                            // 2. Simula tempo de inicialização e vai para calibração
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    currentFlow = .calibration
                                }
                            }
                        }
                    
                case .calibration:
                    // Tela de Calibração
                    CalibrationView(
                        faceManager: faceManager,
                        onCalibrationComplete: {
                            withAnimation {
                                currentFlow = .mainApp
                            }
                        }
                    )
                    
                case .mainApp:
                    // App Funcional
                    if let vocab = vocabularyManager {
                        ContentView()
                            .environment(faceManager) // Passando via Environment para ContentView e filhos
                            .environment(vocab)
                    } else {
                        // Fallback de erro
                        Text("Error loading resources")
                            .foregroundStyle(.white)
                            .background(Color.black)
                    }
                }
            }
            .animation(.easeInOut, value: currentFlow)
        }
    }
}
