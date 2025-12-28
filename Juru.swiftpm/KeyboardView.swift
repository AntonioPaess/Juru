//
//  KeyboardView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

import SwiftUI

struct KeyboardView: View {
    var vocabManager: VocabularyManager
    
    var body: some View {
        // GeometryReader permite ler o tamanho da tela disponível
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            // No iPad, as bolas podem ser maiores, mas não gigantes. Limitamos a 250px.
            // No iPhone, elas ocupam metade da tela menos margens.
            let ballSize = min(availableWidth * 0.4, 250)
            
            HStack(spacing: 0) {
                Spacer()
                
                // BOLA ESQUERDA
                NeonBall(
                    text: vocabManager.leftLabel,
                    color: .cyan,
                    positionLabel: "LEFT",
                    size: ballSize
                )
                
                Spacer() // Espaço dinâmico no meio
                
                // BOLA DIREITA
                NeonBall(
                    text: vocabManager.rightLabel,
                    color: .pink,
                    positionLabel: "RIGHT",
                    size: ballSize
                )
                
                Spacer()
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        // Altura mínima para garantir que cabe
        .frame(height: 300)
    }
}

struct NeonBall: View {
    let text: String
    let color: Color
    let positionLabel: String
    let size: CGFloat // Tamanho recebido dinamicamente
    
    var body: some View {
        ZStack {
            // Círculo com Glow
            Circle()
                .stroke(color, lineWidth: 3)
                .shadow(color: color.opacity(0.8), radius: 15)
                .background(Color.black.opacity(0.01))
            
            // Texto Adaptável
            Text(text)
                .font(.system(size: fontSizeFor(text, size), weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(10)
                .shadow(radius: 5)
                .minimumScaleFactor(0.4)
            
            // Label de Posição
            VStack {
                Spacer()
                HStack(spacing: 4) {
                    if positionLabel == "LEFT" { Image(systemName: "arrow.left") }
                    Text(positionLabel)
                        .font(.system(size: size * 0.08, weight: .black)) // Fonte relativa ao tamanho
                    if positionLabel == "RIGHT" { Image(systemName: "arrow.right") }
                }
                .foregroundStyle(color)
                .padding(.bottom, size * 0.15) // Padding relativo
            }
        }
        .frame(width: size, height: size) // Quadrado perfeito
    }
    
    // Calcula tamanho da fonte baseado no tamanho da bola
    func fontSizeFor(_ text: String, _ ballSize: CGFloat) -> CGFloat {
        if text.count <= 2 { return ballSize * 0.35 } // Grande para letras
        if text.count <= 10 { return ballSize * 0.15 } // Médio para palavras
        return ballSize * 0.10 // Pequeno para listas
    }
}

#Preview {
    let faceManager = FaceTrackingManager()
    let vocabManager = VocabularyManager(faceManager: faceManager)
    ZStack {
        Color.black.ignoresSafeArea()
        KeyboardView(vocabManager: vocabManager)
    }
}
