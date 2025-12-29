//
//  CalibrationView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

import SwiftUI

struct CalibrationView: View {
    var faceManager: FaceTrackingManager
    var onCalibrationComplete: () -> Void
    
    // Estados do Processo de Calibração
    enum CalibState {
        case neutral
        case smileLeft
        case smileRight
        case pucker
        case finished
    }
    @State private var state: CalibState = .neutral
    @State private var maxValue: Float = 0.0
    
    var body: some View {
        ZStack {
            // 1. Fundo Escuro (Igual à foto)
            Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                // 2. A CÂMERA (O quadrado no topo da foto)
                ZStack {
                    // O Container da Câmera vai aqui dentro para ser visível
                    ARViewContainer(manager: faceManager)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    // Overlay de texto técnico (estilo a foto "TRACKING ACTIVE")
                    VStack {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("TRACKING_ACTIVE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.5))
                                Text("60 FPS")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.cyan)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding()
                }
                .frame(height: 350) // Altura do quadrado da câmera
                .padding(.horizontal)
                .padding(.top, 20)
                
                // 3. INSTRUÇÃO CENTRAL
                Text(instructionText)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(height: 60)
                    .padding(.horizontal)
                
                // 4. BARRAS DE DADOS (Igual à parte inferior da foto)
                VStack(spacing: 25) {
                    // Barra Esquerda (Cyan)
                    HUDProgressBar(
                        label: "MOUTHSMILELEFT",
                        value: Float(faceManager.smileLeft),
                        color: .cyan,
                        isActive: state == .smileLeft
                    )
                    
                    // Barra Direita (Vermelho)
                    HUDProgressBar(
                        label: "MOUTHSMILE RIGHT",
                        value: Float(faceManager.smileRight),
                        color: Color(red: 1.0, green: 0.27, blue: 0.23), // Vermelho Neon
                        isActive: state == .smileRight
                    )
                    
                    // Barra Bico (Verde - JawOpen/Pucker)
                    HUDProgressBar(
                        label: "MOUTH PUCKER",
                        value: Float(faceManager.mouthPucker),
                        color: Color(red: 0.2, green: 0.84, blue: 0.29), // Verde Neon
                        isActive: state == .pucker
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                Spacer()
                
                // Botão de Ação
                Button(action: nextStep) {
                    Text(buttonText)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        // Monitoramento de máximos
        .onChange(of: faceManager.smileLeft) { _, new in if state == .smileLeft { maxValue = max(maxValue, Float(new)) } }
        .onChange(of: faceManager.smileRight) { _, new in if state == .smileRight { maxValue = max(maxValue, Float(new)) } }
        .onChange(of: faceManager.mouthPucker) { _, new in if state == .pucker { maxValue = max(maxValue, Float(new)) } }
    }
    
    // Lógica de Texto
    var instructionText: String {
        switch state {
        case .neutral: return "Relax face to define neutral state."
        case .smileLeft: return "Smile to the LEFT."
        case .smileRight: return "Smile to the RIGHT."
        case .pucker: return "Make a PUCKER (Kiss)."
        case .finished: return "Calibration Complete."
        }
    }
    
    var buttonText: String {
        state == .finished ? "START APP" : "NEXT STEP"
    }
    
    func nextStep() {
        switch state {
        case .neutral:
            state = .smileLeft
            maxValue = 0
        case .smileLeft:
            faceManager.setCalibrationMax(for: "smileLeft", value: maxValue)
            state = .smileRight
            maxValue = 0
        case .smileRight:
            faceManager.setCalibrationMax(for: "smileRight", value: maxValue)
            state = .pucker
            maxValue = 0
        case .pucker:
            faceManager.setCalibrationMax(for: "pucker", value: maxValue)
            state = .finished
        case .finished:
            onCalibrationComplete()
        }
    }
}

// COMPONENTE VISUAL: A Barra de Progresso Estilo HUD
struct HUDProgressBar: View {
    let label: String
    let value: Float
    let color: Color
    let isActive: Bool // Se estamos calibrando esta barra agora
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Label e Valor Numérico
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                    .tracking(1.0) // Espaçamento entre letras
                
                Spacer()
                
                Text(String(format: "%.2f", value))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
            }
            
            // A Barra
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Fundo da barra (cinza escuro)
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    // Frente da barra (colorida)
                    Capsule()
                        .fill(color)
                        .frame(width: CGFloat(value) * geo.size.width, height: 8)
                        // Brilho extra se for a ativa
                        .shadow(color: isActive ? color.opacity(0.8) : .clear, radius: 8)
                    
                    // Marcador de "Pico" (Onde o usuário chegou)
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


