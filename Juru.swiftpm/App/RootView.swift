//
//  RootView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

import SwiftUI

struct RootView: View {
    // MARK: - Dependencies
    var faceManager: FaceTrackingManager
    @Binding var vocabularyManager: VocabularyManager?
    
    // MARK: - Persistent State
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // MARK: - Navigation State
    @State private var showCalibrationSheet = false
    @State private var showOnboarding = false
    
    // MARK: - Computed Properties
    private var isGamePaused: Bool {
        showOnboarding || showCalibrationSheet
    }
    
    var body: some View {
        ZStack {
            // ---------------------------------------------------------
            // CAMADA 0: Motor AR
            // ---------------------------------------------------------
            if !faceManager.isCameraDenied {
                ARViewContainer(manager: faceManager)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                    .opacity(0)
            }
            
            // ---------------------------------------------------------
            // CAMADA 1: App Principal
            // ---------------------------------------------------------
            if let vocab = vocabularyManager {
                MainTypingView(
                    vocabManager: vocab,
                    faceManager: faceManager,
                    isPaused: isGamePaused
                )
                .blur(radius: isGamePaused ? 10 : 0)
                .scaleEffect(isGamePaused ? 0.92 : 1.0)
                .opacity(isGamePaused ? 0.6 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isGamePaused)
                .disabled(isGamePaused)
            } else {
                Color.juruBackground.ignoresSafeArea()
            }
            
            // ---------------------------------------------------------
            // CAMADA EXTRA: Controles de Debug (Com SKIP)
            // ---------------------------------------------------------
            #if targetEnvironment(simulator)
            VStack {
                Spacer()
                DebugControls(
                    faceManager: faceManager,
                    onSkip: {
                        // AÇÃO DE SKIP:
                        print("DEBUG: Skipping Setup...")
                        
                        // 1. Força uma calibração fake
                        // Ao definir isso, o manager salva no UserDefaults automaticamente
                        faceManager.calibration = UserCalibration()
                        
                        // 2. Marca onboarding como feito
                        hasCompletedOnboarding = true
                        
                        // 3. Fecha todas as telas modais
                        withAnimation {
                            showOnboarding = false
                            showCalibrationSheet = false
                        }
                    }
                )
            }
            .zIndex(999)
            .transition(.move(edge: .bottom))
            #endif
        }
        .task {
            await setupApp()
        }
        // ---------------------------------------------------------
        // MODAL 1: Onboarding
        // ---------------------------------------------------------
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(faceManager: faceManager) {
                hasCompletedOnboarding = true
                showOnboarding = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showCalibrationSheet = true
                }
            }
        }
        // ---------------------------------------------------------
        // MODAL 2: Calibração
        // ---------------------------------------------------------
        .sheet(isPresented: $showCalibrationSheet) {
            CalibrationView(
                faceManager: faceManager,
                onCalibrationComplete: {
                    showCalibrationSheet = false
                }
            )
            .interactiveDismissDisabled(true)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
        }
    }
    
    @MainActor
    private func setupApp() async {
        if vocabularyManager == nil {
            vocabularyManager = VocabularyManager(faceManager: faceManager)
        }
        
        if !hasCompletedOnboarding {
            showOnboarding = true
        } else if !faceManager.hasSavedCalibration {
            showCalibrationSheet = true
        }
    }
}
