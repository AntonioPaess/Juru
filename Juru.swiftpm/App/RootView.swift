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
    
    enum AppFlow {
        case loading
        case onboarding
        case permissionDenied
        case calibration
        case mainApp
    }
    @State private var currentFlow: AppFlow = .loading
    
    var body: some View {
        ZStack {
            // Camera Background
            if currentFlow != .permissionDenied {
                ARViewContainer(manager: faceManager)
                    .ignoresSafeArea()
            }
            
            // UI Layer
            Group {
                switch currentFlow {
                case .loading:
                    JuruLoadingView()
                        .onAppear { handleLoadingSequence() }
                    
                case .onboarding:
                    OnboardingView(faceManager: faceManager) {
//                        hasCompletedOnboarding = true para testes decomentar depois
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
                        ContentUnavailableView("Error", systemImage: "exclamationmark.triangle")
                    }
                }
            }
            .background(Color.juruBackground.ignoresSafeArea())
            .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.5), value: currentFlow)
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
    
    @MainActor
    private func checkPrerequisites() async {
        if faceManager.isCameraDenied {
            currentFlow = .permissionDenied
            return
        }
        
        if !hasCompletedOnboarding {
            withAnimation { currentFlow = .onboarding }
        } else if faceManager.hasSavedCalibration {
            withAnimation { currentFlow = .mainApp }
        } else {
            withAnimation { currentFlow = .calibration }
        }
    }
}
