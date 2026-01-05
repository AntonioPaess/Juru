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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // Removemos o case .loading
    enum AppFlow {
        case checking // Estado rápido e invisível apenas para decisão
        case onboarding
        case permissionDenied
        case calibration
        case mainApp
    }
    
    // Inicia verificando, sem tela de carregamento visual
    @State private var currentFlow: AppFlow = .checking
    
    var body: some View {
        ZStack {
            // A câmera roda no fundo para tracking (exceto se negado)
            if currentFlow != .permissionDenied {
                ARViewContainer(manager: faceManager)
                    .ignoresSafeArea()
            }
            
            // Camada de UI
            Group {
                switch currentFlow {
                case .checking:
                    // Mantém o fundo da marca enquanto decide (é imperceptível)
                    Color.juruBackground.ignoresSafeArea()
                        .task { await setupApp() }
                    
                case .onboarding:
                    OnboardingView(faceManager: faceManager) {
//                        hasCompletedOnboarding = true
                        withAnimation { currentFlow = .calibration }
                    }
                    
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
                        // Fallback de segurança apenas se houver erro
                        Color.juruBackground.ignoresSafeArea()
                    }
                }
            }
            .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.5), value: currentFlow)
    }
    
    @MainActor
    private func setupApp() async {
        // 1. Inicializa o VocabularyManager imediatamente (sem delay artificial)
        if vocabularyManager == nil {
            vocabularyManager = VocabularyManager(faceManager: faceManager)
        }
        
        // 2. Verifica permissões
        if faceManager.isCameraDenied {
            currentFlow = .permissionDenied
            return
        }
        
        // 3. Decide a navegação instantaneamente
        if !hasCompletedOnboarding {
            currentFlow = .onboarding
        } else if faceManager.hasSavedCalibration {
            currentFlow = .mainApp
        } else {
            currentFlow = .calibration
        }
    }
}
