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
    @Environment(\.colorScheme) var colorScheme
    
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.juruBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack(alignment: .center) {
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundStyle(Color.juruTeal)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        StatusIndicator(isActive: faceManager.isTriggeringLeft, color: .juruTeal)
                        StatusIndicator(isActive: faceManager.isTriggeringRight, color: .juruTeal)
                        StatusIndicator(isActive: faceManager.isTriggeringBack, color: .juruCoral)
                    }
                    .padding(12)
                    .background(Color.juruCardBackground.opacity(0.8))
                    .cornerRadius(30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.juruText.opacity(0.1), lineWidth: 1)
                    )
                    
                    Spacer()
                    
                    Image(systemName: "waveform")
                        .font(.title2)
                        .foregroundStyle(Color.juruSecondaryText)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                VStack(alignment: .leading) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(vocabManager.currentMessage.isEmpty ? "Tap with your smile..." : vocabManager.currentMessage)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(vocabManager.currentMessage.isEmpty ? Color.juruSecondaryText : Color.juruText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(30)
                                .id("bottom")
                        }
                        .onChange(of: vocabManager.currentMessage) {
                            withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                        }
                    }
                }
                .frame(height: 180)
                .background(Color.juruCardBackground)
                .cornerRadius(32)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.juruLead.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 15, x: 0, y: 5)
                .padding(.horizontal, 24)
                
                if !vocabManager.suggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(vocabManager.suggestions, id: \.self) { word in
                                Text(word)
                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                    .foregroundStyle(Color.juruText)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.juruCardBackground)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.juruText.opacity(0.1), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
                
                HStack(spacing: 20) {
                    NaturalTypingCard(
                        text: vocabManager.leftLabel,
                        isActive: faceManager.isTriggeringLeft,
                        alignment: .leading
                    )
                    
                    NaturalTypingCard(
                        text: vocabManager.rightLabel,
                        isActive: faceManager.isTriggeringRight,
                        alignment: .trailing
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                HStack(spacing: 8) {
                    Image(systemName: "mouth")
                    Text("Pucker to Undo")
                }
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundStyle(Color.juruSecondaryText)
                .padding(.bottom, 10)
            }
        }
        .onReceive(timer) { _ in
            vocabManager.update()
        }
    }
}

struct NaturalTypingCard: View {
    let text: String
    let isActive: Bool
    let alignment: Alignment
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: alignment) {
            RoundedRectangle(cornerRadius: 28)
                .fill(isActive ? Color.juruTeal : Color.juruCardBackground)
                .shadow(color: isActive ? Color.juruTeal.opacity(0.4) : Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 20, x: 0, y: 10)
            
            Text(text)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(isActive ? .white : Color.juruText)
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 180)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(isActive ? Color.clear : Color.juruText.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isActive)
    }
}

struct StatusIndicator: View {
    let isActive: Bool
    let color: Color
    
    var body: some View {
        Circle()
            .fill(isActive ? color : Color.juruText.opacity(0.2))
            .frame(width: 8, height: 8)
            .scaleEffect(isActive ? 1.5 : 1.0)
            .animation(.spring, value: isActive)
    }
}
