//
//  UIComponents.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 29/12/25.
//

import SwiftUI

// MARK: - Componentes de Calibração (Neon Guides)

struct NeonGuideCircle: View {
    var isActive: Bool
    var color: Color
    var value: Float
    
    var body: some View {
        ZStack {
            // Glow Externo
            Circle()
                .stroke(color.opacity(isActive ? 0.8 : 0.3), lineWidth: isActive ? 4 : 2)
                .shadow(color: color.opacity(isActive ? 1.0 : 0.0), radius: 20)
                .frame(width: 100, height: 100)
            
            // Preenchimento Interno
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 100 * CGFloat(value), height: 100 * CGFloat(value))
        }
        .animation(.spring(response: 0.3), value: value)
    }
}

struct NeonGuideCapsule: View {
    var isActive: Bool
    var color: Color
    var value: Float
    
    var body: some View {
        ZStack {
            Capsule()
                .stroke(color.opacity(isActive ? 0.8 : 0.3), lineWidth: isActive ? 4 : 2)
                .shadow(color: color.opacity(isActive ? 1.0 : 0.0), radius: 20)
                .frame(width: 120, height: 60)
            
            Capsule()
                .fill(color.opacity(0.3))
                .frame(width: 120 * CGFloat(value), height: 60 * CGFloat(value))
        }
        .animation(.spring(response: 0.3), value: value)
    }
}

// MARK: - Barra de Progresso Estilo HUD

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

// MARK: - Bolas Neon do Teclado

struct NeonBall: View {
    let text: String
    let color: Color
    let positionLabel: String
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: 3)
                .shadow(color: color.opacity(0.8), radius: 15)
                .background(Color.black.opacity(0.01))
            
            Text(text)
                .font(.system(size: fontSizeFor(text, size), weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(10)
                .shadow(radius: 5)
                .minimumScaleFactor(0.4)
            
            VStack {
                Spacer()
                HStack(spacing: 4) {
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
