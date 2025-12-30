//
//  JuruLoadingView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

import SwiftUI

struct JuruLoadingView: View {
    @State private var isAnimating = false
    @State private var scanLineOffset: CGFloat = -100
    @State private var opacityVal = 0.3
    
    // Paleta Cyberpunk
    let neonCyan = Color(red: 0.0, green: 0.95, blue: 1.0)
    let neonPurple = Color(red: 0.7, green: 0.0, blue: 1.0)
    
    var body: some View {
        ZStack {
            // 1. Fundo Profundo (Deep Space)
            Color.black.ignoresSafeArea()
            
            // 2. Luz de Fundo (Ambient Glow)
            ZStack {
                Circle()
                    .fill(neonPurple)
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(x: -100, y: -200)
                    .opacity(0.4)
                
                Circle()
                    .fill(neonCyan)
                    .frame(width: 250, height: 250)
                    .blur(radius: 100)
                    .offset(x: 100, y: 200)
                    .opacity(0.3)
            }
            .scaleEffect(isAnimating ? 1.1 : 0.9)
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: isAnimating)
            
            VStack(spacing: 40) {
                Spacer()
                
                // 3. Ícone Central: Conceito "Boca Digital / Scanner"
                ZStack {
                    // Círculos de "Alvo" (HUD Style)
                    Circle()
                        .stroke(
                            AngularGradient(colors: [neonCyan.opacity(0), neonCyan, neonCyan.opacity(0)], center: .center),
                            lineWidth: 2
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: isAnimating)
                    
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(width: 150, height: 150)
                    
                    // Ícone Símbolo (Face/Sorriso) com efeito Neon
                    Image(systemName: "face.smiling") // Ou "mouth" se disponível no SF Symbols 6
                        .font(.system(size: 60, weight: .thin))
                        .foregroundStyle(.white)
                        .shadow(color: neonCyan, radius: 20)
                        .overlay {
                            // Linha de Scanner passando
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, neonCyan.opacity(0.8), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 20)
                                .offset(y: scanLineOffset)
                                .mask(Image(systemName: "face.smiling").font(.system(size: 60, weight: .thin)))
                        }
                }
                
                // 4. Tipografia
                VStack(spacing: 12) {
                    Text("JURU")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(2) // Espaçamento entre letras
                        .shadow(color: neonPurple.opacity(0.8), radius: 15, x: 0, y: 0)
                    
                    // Texto Técnico (Monospaced = Tech feel)
                    HStack(spacing: 4) {
                        Text("SYSTEM_READY")
                        Text("•")
                            .foregroundStyle(neonCyan)
                        Text("FACE_ENGINE_V1.0")
                    }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
                
                // 5. Indicador de Loading Minimalista
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: neonCyan))
                        .scaleEffect(1.2)
                    
                    Text("Calibrating Neural Mesh...")
                        .font(.caption.monospaced())
                        .foregroundStyle(neonCyan.opacity(0.8))
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            isAnimating = true
            
            // Animação do Scanner
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                scanLineOffset = 40
            }
        }
    }
}

#Preview {
    JuruLoadingView()
}
