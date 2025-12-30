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
        case calibration
        case mainApp
    }
    @State private var currentFlow: AppFlow = .loading
    @State private var isAuthenticating = false
    
    var body: some View {
        ZStack {
            switch currentFlow {
            case .loading:
                JuruLoadingView()
                    .onAppear {
                        handleLoadingSequence()
                    }
                
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
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                        Text("Error loading vocabulary")
                    }
                    .foregroundStyle(.white)
                }
            }
            
            if isAuthenticating {
                Color.black.opacity(0.5).ignoresSafeArea()
                ProgressView("Verifying Face ID...")
                    .foregroundStyle(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
        }
        .animation(.easeInOut, value: currentFlow)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                faceManager.pause()
            } else if newPhase == .active && currentFlow != .loading {
                if let session = faceManager.currentSession {
                    faceManager.start(session: session)
                }
            }
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
        if faceManager.hasSavedCalibration {
            isAuthenticating = true
            let success = await BiometricAuth.authenticate()
            isAuthenticating = false
            
            if success {
                withAnimation { currentFlow = .mainApp }
            } else {
                withAnimation { currentFlow = .calibration }
            }
        } else {
            withAnimation { currentFlow = .calibration }
        }
    }
}
