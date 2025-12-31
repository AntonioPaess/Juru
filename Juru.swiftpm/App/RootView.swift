//
//  RootView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

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
            // CAMADA 0: Fundo Base
            Color.black.ignoresSafeArea()
            
            // CAMADA 1: Câmera Persistente (O Coração do App)
            // Ela precisa estar aqui na Raiz para nunca ser desalocada.
            if currentFlow != .permissionDenied {
                ARViewContainer(manager: faceManager)
                    .ignoresSafeArea()
                // MUDANÇA: 1.0 (Visível) sempre que não for loading
                    .opacity(currentFlow == .loading ? 0.0 : 1.0)
            }
            
            // CAMADA 2: Interfaces
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
        // Gerenciamento de Pausa/Retomada do Sistema
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                faceManager.pause()
            } else if newPhase == .active {
                // Tenta retomar a sessão se ela existir
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
            let result = await BiometricAuth.authenticate()
            switch result {
            case .success(true):
                withAnimation { currentFlow = .mainApp }
            case .success(false), .failure:
                withAnimation { currentFlow = .calibration }
            }
        } else {
            withAnimation { currentFlow = .calibration }
        }
    }
}
