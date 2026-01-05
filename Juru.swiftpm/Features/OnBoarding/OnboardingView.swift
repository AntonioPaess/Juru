//
//  OnboardingView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 04/01/26.
//

import SwiftUI

struct OnboardingView: View {
    var faceManager: FaceTrackingManager
    var onFinished: () -> Void
    
    @State private var currentPage = 0
    @State private var animateBlobs = false
    
    var body: some View {
        ZStack {
            Color.juruBackground.ignoresSafeArea()
            
            // Fundo Dinâmico (Blobs respirando)
            ZStack {
                Circle()
                    .fill(Color.juruTeal.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .scaleEffect(animateBlobs ? 1.2 : 0.8)
                    .offset(x: -100, y: -200)
                    .blur(radius: 60)
                
                Circle()
                    .fill(Color.juruCoral.opacity(0.15))
                    .frame(width: 350, height: 350)
                    .scaleEffect(animateBlobs ? 1.1 : 0.9)
                    .offset(x: 150, y: 300)
                    .blur(radius: 50)
            }
            .animation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true), value: animateBlobs)
            .onAppear { animateBlobs = true }
            
            // Conteúdo Paginado (A Historinha)
            TabView(selection: $currentPage) {
                
                // ATO 1: A ORIGEM (Usando sua Logo)
                OnboardingCard(
                    customImage: "Juru-White", // Sua logo aqui
                    systemIcon: nil,
                    title: "Roots of Speech",
                    description: "In the Tupi language, 'Juru' means Mouth.\nIt represents the sacred origin of our voice and connection.",
                    buttonTitle: "Discover Juru",
                    accentColor: .juruTeal,
                    action: { nextPage() }
                )
                .tag(0)
                
                // ATO 2: A TRANSFORMAÇÃO
                OnboardingCard(
                    customImage: nil,
                    systemIcon: "mouth.fill", // Ícone de sorriso/fala
                    title: "Voice through Smiles",
                    description: "We believe your smile has power.\nJuru transforms your facial gestures into words, giving you a new way to speak.",
                    buttonTitle: "How it works",
                    accentColor: .juruCoral,
                    action: { nextPage() }
                )
                .tag(1)
                
                // ATO 3: A AÇÃO
                OnboardingCard(
                    customImage: nil,
                    systemIcon: "face.smiling.inverse", // Ícone técnico de calibração
                    title: "Let's Find Your Voice",
                    description: "To start, I need to learn your unique smile.\nIt takes just a few seconds to calibrate.",
                    buttonTitle: "Start Calibration",
                    accentColor: .juruTeal,
                    action: { onFinished() }
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .transition(.opacity)
    }
    
    func nextPage() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentPage += 1
        }
    }
}

// MARK: - Card Component Atualizado
struct OnboardingCard: View {
    // Agora aceita ou imagem customizada (Logo) ou ícone do sistema
    let customImage: String?
    let systemIcon: String?
    
    let title: String
    let description: String
    let buttonTitle: String
    let accentColor: Color
    let action: () -> Void
    
    @State private var isAppearing = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Lógica de Ícone vs Logo
            if let customImage = customImage {
                // Exibe a Logo do App
                Image(customImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120) // Tamanho bom para logo
                    .shadow(color: accentColor.opacity(0.5), radius: 20, y: 10)
                    .scaleEffect(isAppearing ? 1.0 : 0.5)
                    .opacity(isAppearing ? 1.0 : 0.0)
            } else if let systemIcon = systemIcon {
                // Exibe Ícones SF Symbols
                Image(systemName: systemIcon)
                    .font(.system(size: 90))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.bottom, 20)
                    .symbolEffect(.bounce, value: isAppearing)
                    .scaleEffect(isAppearing ? 1.0 : 0.5)
                    .opacity(isAppearing ? 1.0 : 0.0)
            }
            
            // Títulos e Textos
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.juruText)
                
                Text(description)
                    .font(.title3) // Tamanho legível e elegante
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.juruSecondaryText)
                    .padding(.horizontal, 40)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(6) // Mais respiro entre linhas
            }
            .offset(y: isAppearing ? 0 : 20)
            .opacity(isAppearing ? 1.0 : 0.0)
            
            Spacer()
            
            // Botão Principal
            Button(action: action) {
                Text(buttonTitle)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(accentColor)
                    .clipShape(Capsule())
                    .shadow(color: accentColor.opacity(0.4), radius: 12, y: 6)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
            .opacity(isAppearing ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8)) {
                isAppearing = true
            }
        }
    }
}
