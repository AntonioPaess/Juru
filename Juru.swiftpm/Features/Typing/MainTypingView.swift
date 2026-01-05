//
//  MainTypingView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 24/12/25.
//

import SwiftUI

struct MainTypingView: View {
    @Bindable var vocabManager: VocabularyManager
    var faceManager: FaceTrackingManager
    var isPaused: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var sizeClass
    
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var isPad: Bool { sizeClass == .regular }
    
    var body: some View {
        ZStack {
            // 1. AMBIENT BACKGROUND
            AmbientBackground()
            
            VStack(spacing: 0) {
                
                // 2. HEADER
                HStack {
                    // LOGO OFICIAL
                    Image("Juru-White")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .shadow(color: .juruTeal.opacity(0.5), radius: 8)
                    
                    Spacer()
                    
                    if faceManager.isTriggeringBack {
                        Label("Undo Ready", systemImage: "arrow.uturn.backward")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.juruCoral)
                            .clipShape(Capsule())
                            .shadow(color: .juruCoral.opacity(0.4), radius: 8, y: 4)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // 3. TEXT OUTPUT
                TypingDisplayCard(text: vocabManager.currentMessage)
                    .frame(maxHeight: isPad ? 240 : 180)
                    .padding(.horizontal, isPad ? 80 : 24)
                    .layoutPriority(1)
                
                // 4. SUGGESTIONS
                if !vocabManager.suggestions.isEmpty {
                    SuggestionBar(suggestions: vocabManager.suggestions)
                        .padding(.top, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
                
                // 5. VISUAL FEEDBACK (Avatar Falando/Sorrindo)
                FeedbackCenter(
                    faceManager: faceManager,
                    isSpeaking: vocabManager.isSpeaking // Conecta o estado de fala
                )
                .padding(.vertical, 20)
                .scaleEffect(isPad ? 1.3 : 1.0)
                
                Spacer()
                
                // 6. ACTION CARDS
                HStack(spacing: 24) {
                    ActionCard(
                        title: vocabManager.leftLabel,
                        icon: "arrow.left",
                        color: .juruTeal,
                        isActive: faceManager.isTriggeringLeft,
                        alignment: .leading
                    )
                    
                    ActionCard(
                        title: vocabManager.rightLabel,
                        icon: "arrow.right",
                        color: .juruCoral,
                        isActive: faceManager.isTriggeringRight,
                        alignment: .trailing
                    )
                }
                .frame(height: 200)
                .padding(.horizontal, isPad ? 80 : 24)
                .padding(.bottom, 20)
                
                // 7. FOOTER
                HStack(spacing: 6) {
                    Image(systemName: "mouth")
                    Text("Pucker to Undo")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.juruSecondaryText)
                .opacity(0.6)
                .padding(.bottom, 20)
            }
        }
        .onReceive(timer) { _ in
            if !isPaused { vocabManager.update() }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: vocabManager.suggestions)
        .animation(.default, value: faceManager.isTriggeringBack)
    }
}

// MARK: - Components Visuais

struct AmbientBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Color.juruBackground.ignoresSafeArea()
            
            GeometryReader { proxy in
                Circle()
                    .fill(Color.juruTeal.opacity(0.08))
                    .frame(width: 600, height: 600)
                    .blur(radius: 100)
                    .offset(x: -200, y: -200)
                
                Circle()
                    .fill(Color.juruCoral.opacity(0.08))
                    .frame(width: 500, height: 500)
                    .blur(radius: 100)
                    .position(x: proxy.size.width, y: proxy.size.height)
            }
        }
    }
}

struct TypingDisplayCard: View {
    var text: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                Text(text.isEmpty ? "Start smiling..." : text)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(text.isEmpty ? Color.secondary.opacity(0.5) : Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(32)
                    .animation(.default, value: text)
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.5), lineWidth: 1)
        )
    }
}

struct SuggestionBar: View {
    var suggestions: [String]
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(suggestions, id: \.self) { word in
                    Text(word)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                }
            }
            .padding(.horizontal, sizeClass == .regular ? 80 : 24)
            .padding(.vertical, 10)
        }
    }
}

struct FeedbackCenter: View {
    var faceManager: FaceTrackingManager
    var isSpeaking: Bool
    
    var activeColor: Color {
        if faceManager.isTriggeringLeft { return .juruTeal }
        if faceManager.isTriggeringRight { return .juruCoral }
        return .clear
    }
    
    var body: some View {
        HStack(spacing: 40) {
            IntensityGauge(value: faceManager.smileLeft, color: .juruTeal, isLeft: true)
            
            ZStack {
                // ANIMAÇÃO DE FALA (Ondas Sonoras)
                if isSpeaking {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(
                                LinearGradient(colors: [.juruTeal, .juruCoral], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2
                            )
                            .frame(width: 120, height: 120)
                            .scaleEffect(isSpeaking ? 2.0 : 1.0)
                            .opacity(isSpeaking ? 0.0 : 1.0)
                            .animation(
                                .easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.4),
                                value: isSpeaking
                            )
                    }
                }
                
                // Halo de Atividade (Se não estiver falando)
                if !isSpeaking {
                    Circle()
                        .fill(activeColor.opacity(0.2))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                        .scaleEffect(activeColor == .clear ? 0.5 : 1.2)
                        .animation(.spring, value: activeColor)
                }
                
                // Avatar Base
                Circle()
                    .fill(Color.juruCardBackground)
                    .shadow(color: Color.black.opacity(0.15), radius: 15, y: 8)
                    .frame(width: 120, height: 120)
                
                JuruAvatarView(faceManager: faceManager, size: 100)
            }
            
            IntensityGauge(value: faceManager.smileRight, color: .juruCoral, isLeft: false)
        }
    }
}

struct IntensityGauge: View {
    var value: Double; var color: Color; var isLeft: Bool
    private var fillHeight: CGFloat { let visualValue = CGFloat(min(value * 1.5, 1.0)); return visualValue * 60 }
    
    var body: some View {
        HStack(spacing: 8) {
            if isLeft { label }
            ZStack(alignment: .bottom) {
                Capsule().fill(Color.gray.opacity(0.1)).frame(width: 6, height: 60)
                Capsule().fill(color).frame(width: 6, height: fillHeight)
                    .shadow(color: color.opacity(0.5), radius: 4)
                    .animation(.linear(duration: 0.1), value: value)
            }
            if !isLeft { label }
        }
    }
    var label: some View { Text(isLeft ? "L" : "R").font(.caption2.bold()).foregroundStyle(Color.secondary) }
}

struct ActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let isActive: Bool
    let alignment: Alignment
    
    var body: some View {
        ZStack(alignment: alignment) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isActive ? [color, color.opacity(0.8)] : [Color.juruCardBackground, Color.juruCardBackground.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: isActive ? color.opacity(0.4) : Color.black.opacity(0.05),
                    radius: isActive ? 20 : 10,
                    y: isActive ? 10 : 5
                )
            
            VStack(alignment: alignment == .leading ? .leading : .trailing) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isActive ? .white : color)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(isActive ? .white.opacity(0.2) : color.opacity(0.1))
                    )
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(isActive ? .white : Color.primary)
                    .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
                    .lineLimit(3)
                    .minimumScaleFactor(0.5)
                    .padding(.bottom, 4)
            }
            .padding(24)
        }
        .scaleEffect(isActive ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
    }
}
