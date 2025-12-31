//
//  MainTypingView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 24/12/25.
//

import SwiftUI
import AVFoundation

struct MainTypingView: View {
    @Bindable var vocabManager: VocabularyManager
    var faceManager: FaceTrackingManager
    
    // Motor de atualização
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // FUNDO DINÂMICO
            // CORREÇÃO: Sem '$' aqui
            if vocabManager.isDarkMode {
                Color.clear
                RadialGradient(
                    colors: [.clear, .black.opacity(0.9)],
                    center: .center,
                    startRadius: 100,
                    endRadius: 500
                )
                .ignoresSafeArea()
            } else {
                Color.white.opacity(0.85)
            }
            
            VStack(spacing: 16) {
                // --- BARRA SUPERIOR ---
                HStack(alignment: .top) {
                    Spacer()
                    
                    // STATUS DO ROSTO
                    HStack(spacing: 6) {
                        StatusDot(color: .cyan, isActive: faceManager.isTriggeringLeft)
                        StatusDot(color: .pink, isActive: faceManager.isTriggeringRight)
                        StatusDot(color: .green, isActive: faceManager.isTriggeringBack)
                    }
                    .padding(10)
                    .background(.ultraThinMaterial, in: Capsule())
                    
                    Spacer()
                    
                    // Ícone discreto
                    Image(systemName: "eye.fill")
                        .font(.title3)
                        // CORREÇÃO: Sem '$' aqui
                        .foregroundStyle(vocabManager.isDarkMode ? .white.opacity(0.3) : .black.opacity(0.3))
                }
                .padding(.horizontal)
                .padding(.top)
                
                // --- DISPLAY DE TEXTO ---
                VStack(alignment: .leading) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(vocabManager.currentMessage.isEmpty ? "Start typing..." : vocabManager.currentMessage)
                                .font(.system(size: 36, weight: .medium, design: .rounded))
                                // CORREÇÃO: Sem '$' aqui
                                .foregroundStyle(vocabManager.isDarkMode ? .white : .black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .id("bottom")
                        }
                        .onChange(of: vocabManager.currentMessage) {
                            withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                        }
                    }
                }
                .frame(height: 140)
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        // CORREÇÃO: Sem '$' aqui
                        .stroke(vocabManager.isDarkMode ? .white.opacity(0.1) : .black.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal)
                .shadow(color: .black.opacity(0.1), radius: 10)
                
                Spacer()
                
                // --- PREDICTIONS (Sugestões) ---
                if !vocabManager.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SUGGESTIONS")
                            .font(.caption2)
                            .fontWeight(.bold)
                            // CORREÇÃO: Sem '$' aqui
                            .foregroundStyle(vocabManager.isDarkMode ? .white.opacity(0.5) : .black.opacity(0.5))
                            .padding(.leading, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(vocabManager.suggestions, id: \.self) { word in
                                    Text(word)
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(12)
                                        // CORREÇÃO: Sem '$' aqui
                                        .foregroundStyle(vocabManager.isDarkMode ? .white : .black)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                // CORREÇÃO: Sem '$' aqui
                                                .stroke(vocabManager.isDarkMode ? .white.opacity(0.3) : .black.opacity(0.1), lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // --- INPUT CARDS ---
                HStack(spacing: 16) {
                    TypingZoneCard(
                        text: vocabManager.leftLabel,
                        isActive: faceManager.isTriggeringLeft,
                        color: .cyan,
                        alignment: .leading,
                        // CORREÇÃO: Sem '$' aqui
                        isDark: vocabManager.isDarkMode
                    )
                    
                    TypingZoneCard(
                        text: vocabManager.rightLabel,
                        isActive: faceManager.isTriggeringRight,
                        color: .pink,
                        alignment: .trailing,
                        // CORREÇÃO: Sem '$' aqui
                        isDark: vocabManager.isDarkMode
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // Rodapé
                HStack {
                    Image(systemName: "mouth")
                    Text("Pucker to Undo/Clear")
                }
                .font(.caption)
                // CORREÇÃO: Sem '$' aqui
                .foregroundStyle(vocabManager.isDarkMode ? .white.opacity(0.5) : .black.opacity(0.5))
                .padding(.bottom, 10)
            }
        }
        // CORREÇÃO: Sem '$' aqui
        .preferredColorScheme(vocabManager.isDarkMode ? .dark : .light)
        .onReceive(timer) { _ in
            vocabManager.update()
        }
    }
}

// Componentes Auxiliares
struct TypingZoneCard: View {
    let text: String
    let isActive: Bool
    let color: Color
    let alignment: Alignment
    let isDark: Bool
    
    var body: some View {
        ZStack(alignment: alignment) {
            RoundedRectangle(cornerRadius: 24)
                .fill(isActive ? AnyShapeStyle(color.opacity(0.4)) : AnyShapeStyle(.ultraThinMaterial))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isActive ? color : (isDark ? .white.opacity(0.2) : .black.opacity(0.1)), lineWidth: isActive ? 3 : 1)
                )
                .shadow(color: isActive ? color.opacity(0.6) : .clear, radius: 20)
            
            Text(text)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(isActive ? .white : (isDark ? .white : .black))
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(isActive ? 1.05 : 1.0)
        }
        .frame(height: 160)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
    }
}

struct StatusDot: View {
    let color: Color
    let isActive: Bool
    var body: some View {
        Circle()
            .fill(isActive ? color : Color.gray.opacity(0.3))
            .frame(width: 8, height: 8)
            .scaleEffect(isActive ? 1.4 : 1.0)
            .animation(.spring, value: isActive)
            .shadow(color: isActive ? color : .clear, radius: 4)
    }
}
