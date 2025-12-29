//
//  MainTypingView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

import SwiftUI

struct MainTypingView: View {
    // Injeção Explícita (Seu Padrão)
    var vocabManager: VocabularyManager
    var faceManager: FaceTrackingManager
    
    var body: some View {
        ZStack {
            // 1. FUNDO: Apenas a Câmera Limpa (Sem textos de calibração)
            ARViewContainer(manager: faceManager)
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.6), .black.opacity(0.2), .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // 2. INTERFACE
            VStack(spacing: 0) {
                // --- ÁREA DE TEXTO (Topo) ---
                VStack(alignment: .leading) {
                    Text(vocabManager.currentMessage.isEmpty ? "Smile left to start..." : vocabManager.currentMessage)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.default, value: vocabManager.currentMessage)
                    
                    if !vocabManager.currentMessage.isEmpty {
                        Rectangle()
                            .fill(Color.pink)
                            .frame(width: 3, height: 30)
                            .opacity(0.8)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                // --- SUGESTÕES ---
                if !vocabManager.suggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(vocabManager.suggestions, id: \.self) { word in
                                Text(word)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(.white.opacity(0.1)))
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .frame(height: 40)
                    .padding(.top, 10)
                }
                
                Spacer()
                
                // --- TECLADO NEON ---
                KeyboardView(vocabManager: vocabManager)
                    .padding(.bottom, 40)
            }
        }
        // Conexão Lógica: Ouve o FaceManager e atualiza o VocabManager
        .onChange(of: faceManager.smileRight) { vocabManager.update() }
        .onChange(of: faceManager.smileLeft) { vocabManager.update() }
        .onChange(of: faceManager.mouthPucker) { vocabManager.update() }
        // Adicione também os novos gatilhos se for usar Cabeça/Olhos na MainView
        .onChange(of: faceManager.headYaw) { vocabManager.update() }
        .onChange(of: faceManager.eyeYaw) { vocabManager.update() }
    }
}

#Preview {
    let faceManager = FaceTrackingManager()
    let vocabManager = VocabularyManager(faceManager: faceManager)
    MainTypingView(
        vocabManager: vocabManager,
        faceManager: faceManager
    )
}
