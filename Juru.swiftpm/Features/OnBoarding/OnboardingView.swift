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
    
    @State private var currentStep = 0
    let timer = Timer.publish(every: 6.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.juruBackground.ignoresSafeArea()
            
            // Fundo Vivo (Opacidade ajustada para não brigar com o contraste)
            AmbientBackground()
                .opacity(0.4)
            
            VStack {
                if currentStep == 0 {
                    // ATO 1
                    StoryCard(
                        image: "Juru-White",
                        isSystemIcon: false,
                        title: "The Origin",
                        text: "In the Tupi language, 'Juru' means Mouth.\nIt represents the sacred portal of our voice."
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if currentStep == 1 {
                    // ATO 2
                    StoryCard(
                        image: "waveform.path.ecg",
                        isSystemIcon: true,
                        title: "Silence into Sound",
                        text: "For many, speech is lost, but the smile remains.\nWe believe your smile has power."
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if currentStep == 2 {
                    // ATO 3
                    StoryCard(
                        image: "face.smiling.fill",
                        isSystemIcon: true,
                        title: "Smile to Speak",
                        text: "Juru transforms facial micro-gestures into words.\nA simple smile becomes your voice."
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if currentStep == 3 {
                    // ATO 4
                    VStack(spacing: 40) {
                        StoryCard(
                            image: "slider.horizontal.3",
                            isSystemIcon: true,
                            title: "Let's Begin",
                            text: "To help you speak, I need to learn your unique smile.\nShall we do a quick setup?"
                        )
                        
                        Button(action: onFinished) {
                            Text("Start Calibration")
                                .font(.title3.bold())
                                .foregroundStyle(.white) // Botão sempre branco pois tem fundo colorido
                                .padding(.horizontal, 40)
                                .padding(.vertical, 18)
                                .background(Color.juruTeal)
                                .clipShape(Capsule())
                                .shadow(color: .juruTeal.opacity(0.5), radius: 20, y: 10)
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 1.0), value: currentStep)
        }
        .onReceive(timer) { _ in
            if currentStep < 3 { withAnimation { currentStep += 1 } }
        }
    }
}

struct StoryCard: View {
    let image: String
    let isSystemIcon: Bool
    let title: String
    let text: String
    
    var body: some View {
        VStack(spacing: 32) {
            if isSystemIcon {
                Image(systemName: image)
                    .font(.system(size: 90))
                    // CORREÇÃO: Usa a cor do texto para ícones do sistema
                    .foregroundStyle(Color.juruText)
                    .shadow(color: Color.juruTeal.opacity(0.3), radius: 20)
                    .symbolEffect(.pulse)
            } else {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: .juruTeal.opacity(0.4), radius: 30)
            }
            
            VStack(spacing: 20) {
                Text(title)
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    // CORREÇÃO: Usa cor adaptativa de alto contraste
                    .foregroundStyle(Color.juruText)
                
                Text(text)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    // CORREÇÃO: Usa cor secundária legível
                    .foregroundStyle(Color.juruText.opacity(0.8))
                    .padding(.horizontal, 60)
                    .lineSpacing(8)
            }
        }
        .padding()
    }
}
