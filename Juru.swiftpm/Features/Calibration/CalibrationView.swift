//
//  CalibrationView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 14/12/25.
//

import SwiftUI

struct CalibrationView: View {
    var faceManager: FaceTrackingManager
    var onCalibrationComplete: () -> Void
    
    // Estados do Fluxo
    enum CalibState: CaseIterable {
        case neutral
        case smileLeft
        case smileRight
        case pucker
        case finished
    }
    
    @State private var state: CalibState = .neutral
    @State private var progress: CGFloat = 0.0
    @State private var currentMax: Float = 0.0
    @State private var isHolding: Bool = false
    @State private var lastChangeTime: Date = Date()
    @State private var feedbackText: String = "0%"
    
    // Configuração de Tempo Dinâmica
    var holdDuration: TimeInterval {
        switch state {
        case .neutral: return 4.0 // Mais tempo para estabilizar o neutro
        default: return 1.2       // Rápido para gestos ativos
        }
    }
    
    var body: some View {
        ZStack {
            // REMOVIDO: ARViewContainer (Ele já está no RootView)
            // REMOVIDO: Fundo sólido (Para permitir ver a câmera)
            
            // 1. Vinheta (Para focar no centro e dar contraste sobre a câmera do RootView)
            RadialGradient(
                colors: [.clear, .black.opacity(0.8)],
                center: .center,
                startRadius: 200,
                endRadius: 600
            )
            .ignoresSafeArea()
            
            // 2. Elementos de UI (HUD)
            VStack {
                // Topo: Instrução Principal
                VStack(spacing: 8) {
                    Text(instructionTitle)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: stateColor.opacity(0.8), radius: 10)
                    
                    Text(instructionSubtitle)
                        .font(.title3.monospaced())
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.top, 60)
                .animation(.easeInOut, value: state)
                
                Spacer()
                
                // Centro: Indicador de Progresso Circular
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 20)
                        .frame(width: 220, height: 220)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                colors: [stateColor.opacity(0.5), stateColor],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: stateColor.opacity(0.6), radius: 20)
                        .animation(.linear(duration: 0.1), value: progress)
                    
                    VStack(spacing: 4) {
                        if state == .neutral {
                            Image(systemName: "face.dashed")
                                .font(.system(size: 50))
                                .foregroundStyle(.white.opacity(0.8))
                        } else {
                            Text(feedbackText)
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .contentTransition(.numericText())
                            
                            Text("INTENSITY")
                                .font(.caption.bold())
                                .tracking(2)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .foregroundStyle(.white)
                }
                .scaleEffect(isHolding ? 1.1 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isHolding)
                
                Spacer()
                
                // Rodapé: Feedback Técnico
                HStack(spacing: 20) {
                    StatusPill(label: "LEFT", isActive: state == .smileLeft)
                    StatusPill(label: "RIGHT", isActive: state == .smileRight)
                    StatusPill(label: "PUCKER", isActive: state == .pucker)
                }
                .padding(.bottom, 50)
            }
        }
        .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
            handleLogic()
        }
    }
    
    // MARK: - Lógica Principal
    private func handleLogic() {
        guard state != .finished else { return }
        let currentValue = getCurrentMetricValue()
        let percent = Int(currentValue * 100)
        feedbackText = "\(percent)%"
        
        // No neutro, qualquer valor é válido para contar tempo. Nos gestos, precisa passar do threshold.
        let threshold: Float = (state == .neutral) ? -1.0 : 0.15
        
        if currentValue > threshold {
            if !isHolding {
                isHolding = true
                lastChangeTime = Date()
            }
            if state != .neutral {
                currentMax = max(currentMax, currentValue)
            }
            
            let timeHeld = Date().timeIntervalSince(lastChangeTime)
            progress = min(CGFloat(timeHeld / holdDuration), 1.0)
            
            if progress >= 1.0 {
                completeStep()
            }
        } else {
            isHolding = false
            progress = 0.0
        }
    }
    
    private func completeStep() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        switch state {
        case .neutral: state = .smileLeft
        case .smileLeft:
            faceManager.setCalibrationMax(for: .smileLeft, value: currentMax)
            state = .smileRight
        case .smileRight:
            faceManager.setCalibrationMax(for: .smileRight, value: currentMax)
            state = .pucker
        case .pucker:
            faceManager.setCalibrationMax(for: .pucker, value: currentMax)
            state = .finished
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onCalibrationComplete()
            }
        case .finished: break
        }
        
        currentMax = 0.0
        progress = 0.0
        isHolding = false
        lastChangeTime = Date()
    }
    
    private func getCurrentMetricValue() -> Float {
        switch state {
        case .neutral: return 1.0 // Retorna 1.0 para encher a barra por tempo
        case .smileLeft: return Float(faceManager.smileLeft)
        case .smileRight: return Float(faceManager.smileRight)
        case .pucker: return Float(faceManager.mouthPucker)
        case .finished: return 0.0
        }
    }
    
    var instructionTitle: String {
        switch state {
        case .neutral: return "Relax Face"
        case .smileLeft: return "Smile Left"
        case .smileRight: return "Smile Right"
        case .pucker: return "Make a Kiss"
        case .finished: return "All Set!"
        }
    }
    
    var instructionSubtitle: String {
        switch state {
        case .neutral: return "Stay still for a moment..."
        case .smileLeft: return "Hold it to confirm..."
        case .smileRight: return "Hold it to confirm..."
        case .pucker: return "Hold it to confirm..."
        case .finished: return "Loading experience..."
        }
    }
    
    var stateColor: Color {
        switch state {
        case .neutral: return .white
        case .smileLeft: return .cyan
        case .smileRight: return .pink
        case .pucker: return .green
        case .finished: return .yellow
        }
    }
}

struct StatusPill: View {
    let label: String
    let isActive: Bool
    
    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(isActive ? .black : .white.opacity(0.3))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? Color.white : Color.white.opacity(0.1))
            .cornerRadius(20)
            .animation(.easeInOut, value: isActive)
    }
}
