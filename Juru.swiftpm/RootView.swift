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
    
    enum AppFlow {
        case loading
        case calibration
        case mainApp
    }
    @State private var currentFlow: AppFlow = .loading
    
    var body: some View {
        ZStack {
            switch currentFlow {
            case .loading:
                JuruLoadingView()
                    .onAppear {
                        if vocabularyManager == nil {
                            vocabularyManager = VocabularyManager(faceManager: faceManager)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { currentFlow = .calibration }
                        }
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
                    MainTypingView(
                        vocabManager: vocab,
                        faceManager: faceManager
                    )
                } else {
                    Text("Error loading vocabulary")
                        .foregroundStyle(.white)
                        .background(Color.black)
                }
            }
        }
        .animation(.easeInOut, value: currentFlow)
    }
}
