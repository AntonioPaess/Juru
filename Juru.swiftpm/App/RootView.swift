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
                        tutorialFocus: tutorialFocus // Recebe foco do overlay
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
                        // AGORA É SÓ O OVERLAY (Sem duplicar o App)
                        TutorialView(
                            vocabManager: vocab,
                            faceManager: faceManager,
                            onTutorialComplete: {
                                // Ao completar, apenas removemos o overlay.
                                // O MainApp já está embaixo. Zero flicker.
                                withAnimation(.easeOut(duration: 1.0)) {
                                    currentState = .mainApp
                                    tutorialFocus = .none
                                }
                            },
                            currentFocus: $tutorialFocus // Passa o controle para o tutorial
                        )
                        .transition(.opacity)
                    }
                }
            }
            
            // CAMADA 3: DEBUGGER
            #if targetEnvironment(simulator)
            VStack {
                Spacer()
                if isDebugExpanded {
                    DebugControls(
                        faceManager: faceManager,
                        onSkipAll: {
                            faceManager.calibration = UserCalibration()
                            withAnimation { currentState = .mainApp }
                        },
                        onStartTutorial: {
                            faceManager.calibration = UserCalibration()
                            withAnimation { currentState = .tutorial }
                        },
                        onMinimize: { withAnimation(.spring) { isDebugExpanded = false } }
                    )
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button { withAnimation(.spring) { isDebugExpanded = true } } label: {
                        Image(systemName: "ladybug.fill")
                            .font(.title2).foregroundStyle(.white).frame(width: 50, height: 50)
                            .background(Color.juruTeal).clipShape(Circle()).shadow(radius: 10)
                    }
                    .padding(.bottom, 20)
                    .transition(.scale)
                }
            }
            .zIndex(999)
            #endif
        }
        .task { await setupApp() }
    }
    
    @MainActor private func setupApp() async {
        if vocabularyManager == nil { vocabularyManager = VocabularyManager(faceManager: faceManager) }
        currentState = .onboarding
    }
}
