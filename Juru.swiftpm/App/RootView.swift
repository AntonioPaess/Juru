//
//  RootView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

import SwiftUI
import UIKit

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
    @State private var tutorialAllowsUndo: Bool = false

    // Debugger Toggle
    @State private var isDebugExpanded = true

    var body: some View {
        GeometryReader { geo in
            let isPortrait = geo.size.height > geo.size.width

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
                            tutorialFocus: tutorialFocus,
                            isTutorialActive: currentState == .tutorial,
                            tutorialAllowsUndo: tutorialAllowsUndo
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
                                        tutorialAllowsUndo = true
                                    }
                                },
                                currentFocus: $tutorialFocus,
                                allowsUndo: $tutorialAllowsUndo
                            )
                            .transition(.opacity)
                        }
                    }
                }

                // CAMADA 3: Debug Overlay (Simulator only)
                #if DEBUG
                if DebugConfig.isEnabled {
                    SimulatorDebugOverlay(faceManager: faceManager)
                }
                #endif

                // CAMADA 4: Portrait lock (highest priority overlay)
                PortraitLockOverlay(isPortrait: isPortrait)
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .task { await setupApp() }
    }

    @MainActor private func setupApp() async {
        if vocabularyManager == nil { vocabularyManager = VocabularyManager(faceManager: faceManager) }

        #if DEBUG
        if let startState = DebugConfig.startState {
            switch startState {
            case .calibration:
                currentState = .calibration
            case .tutorial:
                // Set default calibration so tutorial works without real calibration
                faceManager.calibration = UserCalibration()
                currentState = .tutorial
            case .mainApp:
                faceManager.calibration = UserCalibration()
                currentState = .mainApp
            }
            return
        }
        #endif

        currentState = .onboarding
    }
}
