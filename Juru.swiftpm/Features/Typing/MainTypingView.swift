//
//  MainTypingView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 24/12/25.
//

import SwiftUI

enum TutorialFocus: Equatable {
    case none
    case leftButton
    case rightButton
    case suggestions
    case speak
}

struct MainTypingView: View {
    @Bindable var vocabManager: VocabularyManager
    var faceManager: FaceTrackingManager
    var isPaused: Bool
    
    var tutorialFocus: TutorialFocus = .none
    var isTutorialActive: Bool // <--- NOVA VARIÁVEL
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var sizeClass
    
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var isPad: Bool { sizeClass == .regular }
    
    var body: some View {
        ZStack {
            AmbientBackground()
            
            VStack(spacing: 0) {
                // HEADER
                HStack {
                    Image("Juru-White")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .shadow(color: .juruTeal.opacity(0.5), radius: 8)
                    
                    Spacer()
                    
                    if faceManager.puckerState == .readyToBack {
                        Label("Release to Undo", systemImage: "arrow.uturn.backward")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .transition(.scale)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                .padding(.bottom, 10)
                .opacity(shouldDim(.none) ? 0.3 : 1.0)
                
                // TEXTO
                TypingDisplayCard(text: vocabManager.currentMessage)
                    .frame(maxHeight: isPad ? 240 : 180)
                    .padding(.horizontal, isPad ? 80 : 24)
                    .layoutPriority(1)
                    .opacity(shouldDim(.none) ? 0.3 : 1.0)
                
                // SUGESTÕES
                if !vocabManager.suggestions.isEmpty {
                    SuggestionBar(suggestions: vocabManager.suggestions)
                        .padding(.top, 16)
                        .opacity(shouldDim(.suggestions) ? 0.3 : 1.0)
                        .overlay(
                            tutorialFocus == .suggestions ?
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.juruGold, lineWidth: 3)
                                .padding(.horizontal, 20)
                            : nil
                        )
                }
                
                Spacer()
                
                // --- CURSOR CENTRAL ---
                ZStack {
                    FeedbackCenter(
                        faceManager: faceManager,
                        isSpeaking: vocabManager.isSpeaking
                    )
                    
                    if faceManager.puckerState != .idle && faceManager.puckerState != .cooldown {
                        ProgressRing(state: faceManager.puckerState, progress: faceManager.interactionProgress)
                            .frame(width: 160, height: 160)
                    }
                }
                .padding(.vertical, 20)
                .scaleEffect(isPad ? 1.3 : 1.0)
                .opacity(shouldDim(.none) ? 0.5 : 1.0)
                
                Spacer()
                
                // BOTÕES DE AÇÃO
                HStack(spacing: 24) {
                    ActionCard(
                        title: vocabManager.leftLabel,
                        icon: "arrow.left",
                        color: .juruTeal,
                        isActive: faceManager.isTriggeringLeft,
                        alignment: .leading
                    )
                    .opacity(shouldDim(.leftButton) ? 0.3 : 1.0)
                    .overlay(
                        faceManager.currentFocusState == 1 ?
                        RoundedRectangle(cornerRadius: 28).stroke(Color.white, lineWidth: 4) : nil
                    )
                    .scaleEffect(faceManager.currentFocusState == 1 ? 1.05 : 1.0)
                    
                    ActionCard(
                        title: vocabManager.rightLabel,
                        icon: "arrow.right",
                        color: .juruCoral,
                        isActive: faceManager.isTriggeringRight,
                        alignment: .trailing
                    )
                    .opacity(shouldDim(.rightButton) ? 0.3 : 1.0)
                    .overlay(
                        faceManager.currentFocusState == 2 ?
                        RoundedRectangle(cornerRadius: 28).stroke(Color.white, lineWidth: 4) : nil
                    )
                    .scaleEffect(faceManager.currentFocusState == 2 ? 1.05 : 1.0)
                }
                .frame(height: 200)
                .padding(.horizontal, isPad ? 80 : 24)
                .padding(.bottom, 20)
                
                Text(footerInstruction)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.juruSecondaryText)
                    .opacity(0.6)
                    .padding(.bottom, 20)
            }
        }
        .onReceive(timer) { _ in
            if !isPaused {
                var allowAction = false
                
                // --- LÓGICA CORRIGIDA ---
                
                if !isTutorialActive {
                    // MODO NORMAL: Permite tudo (comportamento padrão)
                    allowAction = true
                } else {
                    // MODO TUTORIAL: Aplica a lógica estrita de bloqueio
                    switch tutorialFocus {
                    case .leftButton:
                        if faceManager.currentFocusState == 1 { allowAction = true }
                        
                    case .rightButton:
                        if faceManager.currentFocusState == 2 { allowAction = true }
                        
                    case .none, .suggestions, .speak:
                        allowAction = false
                    }
                }
                
                // UNDO SEMPRE PERMITIDO (Gesto global)
                if faceManager.isBackingOut {
                    allowAction = true
                }
                
                if allowAction {
                    vocabManager.update()
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: tutorialFocus)
    }
    
    var footerInstruction: String {
        switch faceManager.puckerState {
        case .idle: return "Hold Pucker to Select • Long Hold to Undo"
        case .charging: return "Keep holding..."
        case .readyToSelect: return "Release to SELECT"
        case .readyToBack: return "Release to UNDO"
        case .cooldown: return "Relax..."
        }
    }
    
    func shouldDim(_ element: TutorialFocus) -> Bool {
        // Se não estiver no tutorial, não escurece nada
        if !isTutorialActive || tutorialFocus == .none { return false }
        return tutorialFocus != element
    }
}
// Structs auxiliares permanecem iguais...
struct ProgressRing: View {
    var state: PuckerState
    var progress: Double
    var ringColor: Color {
        switch state {
        case .charging: return Color.gray.opacity(0.5)
        case .readyToSelect: return Color.juruTeal
        case .readyToBack: return Color.red
        default: return .clear
        }
    }
    var iconName: String {
        switch state {
        case .readyToSelect: return "checkmark"
        case .readyToBack: return "arrow.uturn.backward"
        default: return "circle.fill"
        }
    }
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.1), lineWidth: 8)
            Circle().trim(from: 0.0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.05), value: progress)
            if state == .readyToSelect || state == .readyToBack {
                Circle().fill(ringColor).frame(width: 40, height: 40)
                    .overlay(Image(systemName: iconName).font(.system(size: 20, weight: .bold)).foregroundStyle(.white))
                    .offset(y: -90).transition(.scale.combined(with: .opacity))
            }
        }
    }
}

struct AmbientBackground: View {
    var body: some View {
        ZStack {
            Color.juruBackground.ignoresSafeArea()
            GeometryReader { proxy in
                Circle().fill(Color.juruTeal.opacity(0.08)).frame(width: 600, height: 600).blur(radius: 100).offset(x: -200, y: -200)
                Circle().fill(Color.juruCoral.opacity(0.08)).frame(width: 500, height: 500).blur(radius: 100).position(x: proxy.size.width, y: proxy.size.height)
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
                    .font(.juruFont(.largeTitle, weight: .bold))
                    .foregroundStyle(text.isEmpty ? Color.secondary.opacity(0.5) : Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(32)
                    .animation(.default, value: text)
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.5), lineWidth: 1))
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
                        .padding(.horizontal, 24).padding(.vertical, 14)
                        .background(.thinMaterial).clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                }
            }
            .padding(.horizontal, sizeClass == .regular ? 80 : 24).padding(.vertical, 10)
        }
    }
}

struct FeedbackCenter: View {
    var faceManager: FaceTrackingManager
    var isSpeaking: Bool
    var activeColor: Color {
        if faceManager.currentFocusState == 1 { return .juruTeal }
        if faceManager.currentFocusState == 2 { return .juruCoral }
        return .clear
    }
    var body: some View {
        HStack(spacing: 40) {
            IntensityGauge(value: faceManager.browUp, color: .juruTeal, isLeft: true)
            ZStack {
                if isSpeaking {
                    ForEach(0..<3) { i in
                        Circle().stroke(LinearGradient(colors: [.juruTeal, .juruCoral], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                            .frame(width: 120, height: 120).scaleEffect(isSpeaking ? 2.0 : 1.0).opacity(isSpeaking ? 0.0 : 1.0)
                            .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(Double(i) * 0.4), value: isSpeaking)
                    }
                }
                if !isSpeaking {
                    Circle().fill(activeColor.opacity(0.2)).frame(width: 140, height: 140).blur(radius: 20)
                        .scaleEffect(activeColor == .clear ? 0.5 : 1.2).animation(.spring, value: activeColor)
                }
                Circle().fill(Color.juruCardBackground).shadow(color: Color.black.opacity(0.15), radius: 15, y: 8).frame(width: 120, height: 120)
                JuruAvatarView(faceManager: faceManager, size: 100)
            }
            IntensityGauge(value: faceManager.mouthPucker, color: .juruCoral, isLeft: false)
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
                Capsule().fill(color).frame(width: 6, height: fillHeight).shadow(color: color.opacity(0.5), radius: 4).animation(.linear(duration: 0.1), value: value)
            }
            if !isLeft { label }
        }
    }
    var label: some View { Text(isLeft ? "B" : "P").font(.caption2.bold()).foregroundStyle(Color.secondary) }
}

struct ActionCard: View {
    let title: String; let icon: String; let color: Color; let isActive: Bool; let alignment: Alignment
    var body: some View {
        ZStack(alignment: alignment) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: isActive ? [color, color.opacity(0.8)] : [Color.juruCardBackground, Color.juruCardBackground.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: isActive ? color.opacity(0.4) : Color.black.opacity(0.05), radius: isActive ? 20 : 10, y: isActive ? 10 : 5)
            VStack(alignment: alignment == .leading ? .leading : .trailing) {
                Image(systemName: icon).font(.title3).foregroundStyle(isActive ? .white : color).padding(12)
                    .background(Circle().fill(isActive ? .white.opacity(0.2) : color.opacity(0.1)))
                Spacer()
                Text(title).font(.juruFont(.title2, weight: .bold)).foregroundStyle(isActive ? .white : Color.primary)
                    .multilineTextAlignment(alignment == .leading ? .leading : .trailing).lineLimit(3).minimumScaleFactor(0.4).padding(.bottom, 4)
            }
            .padding(24)
        }
        .scaleEffect(isActive ? 1.02 : 1.0).animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
    }
}
