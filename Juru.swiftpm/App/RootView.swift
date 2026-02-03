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
    
    // Estado do App
    enum AppState {
        case onboarding, calibration, tutorial, mainApp
    }
    @State private var currentState: AppState = .onboarding
    
    // Foco do Tutorial (Passado para o MainTypingView)
    @State private var tutorialFocus: TutorialFocus = .none
    
    // Debugger Toggle
    @State private var isDebugExpanded = true
    
    var body: some View {
        ZStack {
            // CAMADA 0: ARView (Sempre ativa)
            if !faceManager.isCameraDenied {
                ARViewContainer(manager: faceManager)
                    .ignoresSafeArea().accessibilityHidden(true).opacity(0.01).allowsHitTesting(false)
            }
            Color.juruBackground.ignoresSafeArea()
            
            if let vocab = vocabularyManager {
                
                // CAMADA 1: APP PRINCIPAL (PERSISTENTE)
                // Ele existe desde o início, mas fica escondido ou visível conforme o estado
                if currentState == .tutorial || currentState == .mainApp {
                    MainTypingView(
                        vocabManager: vocab,
                        faceManager: faceManager,
                        isPaused: false,
                        tutorialFocus: tutorialFocus, // Recebe foco do overlay
                        isTutorialActive: currentState == .tutorial // <--- CORREÇÃO AQUI
                    )
                    // Transição suave apenas na primeira aparição
                    .transition(.opacity)
                }
                
                // CAMADA 2: OVERLAYS (Onboarding / Calibration / Tutorial UI)
                Group {
                    if currentState == .onboarding {
                        OnboardingView(faceManager: faceManager) {
                            withAnimation { currentState = .calibration }
                        }
                        .transition(.opacity)
                    }
                    
                    if currentState == .calibration {
                        CalibrationView(
                            faceManager: faceManager,
                            onCalibrationComplete: {
                                withAnimation { currentState = .tutorial }
                            }
                        )
                        .transition(.opacity)
                    }
                    
                    if currentState == .tutorial {
                        TutorialView(
                            vocabManager: vocab,
                            faceManager: faceManager,
                            onTutorialComplete: {
                                withAnimation(.easeOut(duration: 1.0)) {
                                    currentState = .mainApp
                                    tutorialFocus = .none
                                }
                            },
                            currentFocus: $tutorialFocus
                        )
                        .transition(.opacity)
                    }
                }
            }
        }
        .task { await setupApp() }
    }
    
    @MainActor private func setupApp() async {
        if vocabularyManager == nil { vocabularyManager = VocabularyManager(faceManager: faceManager) }
        currentState = .onboarding
    }
}
