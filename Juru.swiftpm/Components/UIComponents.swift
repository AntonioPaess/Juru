//
//  UIComponents.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 29/12/25.
//

import SwiftUI

struct HUDProgressBar: View {
    let label: String
    let value: Float
    let color: Color
    let isActive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                    .tracking(1.0)
                
                Spacer()
                
                Text(String(format: "%.2f", value))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(color)
                        .frame(width: CGFloat(value) * geo.size.width, height: 8)
                        .shadow(color: isActive ? color.opacity(0.8) : .clear, radius: 8)
                    
                    if isActive {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: 12)
                            .offset(x: CGFloat(value) * geo.size.width)
                    }
                }
            }
            .frame(height: 8)
        }
    }
}

struct NeonBall: View {
    let text: String
    let color: Color
    let positionLabel: String
    let size: CGFloat
    
    // Acessibilidade: Escala o tamanho da fonte baseado nas preferências do usuário
    @ScaledMetric(relativeTo: .body) var scaleFactor: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Fundo sutil com Material para melhor contraste em fundos claros/complexos
            Circle()
                .fill(.ultraThinMaterial)
                .opacity(0.5)
            
            Circle()
                .stroke(color, lineWidth: 3)
                .shadow(color: color.opacity(0.8), radius: 15)
            
            Text(text)
                .font(.system(size: fontSizeFor(text, size) * scaleFactor, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(10)
                .shadow(radius: 5)
                .minimumScaleFactor(0.4)
            
            VStack {
                Spacer()
                HStack(spacing: 4) {
                    // SymbolEffect (iOS 17+) - Adiciona uma animação sutil se quiser
                    if positionLabel == "LEFT" { Image(systemName: "arrow.left") }
                    Text(positionLabel)
                        .font(.system(size: size * 0.08, weight: .black))
                    if positionLabel == "RIGHT" { Image(systemName: "arrow.right") }
                }
                .foregroundStyle(color)
                .padding(.bottom, size * 0.15)
            }
        }
        .frame(width: size, height: size)
    }
    
    func fontSizeFor(_ text: String, _ ballSize: CGFloat) -> CGFloat {
        if text.count <= 2 { return ballSize * 0.35 }
        if text.count <= 10 { return ballSize * 0.15 }
        return ballSize * 0.10
    }
}
