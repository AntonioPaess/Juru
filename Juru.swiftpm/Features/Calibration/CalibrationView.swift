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
    @State private var progress: CGFloat = 0.0 // 0.0 a 1.0 (Progresso do Hold)
    @State private var currentMax: Float = 0.0 // O máximo atingido durante o "Hold"
    @State private var isHolding: Bool = false
    
    // Configuração de Tempo (Ajuste fino para o Student Challenge)
    let holdDuration: TimeInterval = 1.2 // Tempo necessário segurando o gesto
    @State private var lastChangeTime: Date = Date()
    
    // Feedback Visual
    @State private var feedbackText: String = "0%"
    
    var body: some View {
        ZStack {
            // 1. Fundo e Câmera
            Color.black.ignoresSafeArea()
            
            ARViewContainer(manager: faceManager)
                .opacity(0.6) // Levemente escurecido para destacar a UI
                .ignoresSafeArea()
                .overlay(
                    // Vinheta para focar no centro
                    RadialGradient(
                        colors: [.clear, .black.opacity(0.8)],
                        center: .center,
                        startRadius: 200,
                        endRadius: 600
                    )
                )
            
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
                    // Círculo de Fundo
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 20)
                        .frame(width: 220, height: 220)
                    
                    // Círculo de Progresso (Hold)
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
                        .animation(.linear(duration: 0.1), value: progress) // Animação fluida
                    
                    // Valor Central (Intensidade ou Contagem)
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
        // Loop de Lógica (Game Loop)
        .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
            handleLogic()
        }
    }
    
    // MARK: - Lógica Principal
    private func handleLogic() {
        guard state != .finished else { return }
        
        let currentValue = getCurrentMetricValue()
        
        // Atualiza texto de porcentagem visual
        let percent = Int(currentValue * 100)
        feedbackText = "\(percent)%"
        
        // Lógica de "Hold" (Segurar)
        // Se estiver no Neutral, qualquer valor baixo é bom.
        // Se estiver nos gestos, precisa superar um limiar mínimo para começar a contar.
        
        let threshold: Float = (state == .neutral) ? -1.0 : 0.15 // 15% de movimento mínimo para ativar
        
        if currentValue > threshold {
            if !isHolding {
                isHolding = true
                lastChangeTime = Date() // Começou a segurar agora
            }
            
            // Atualiza o máximo detectado durante esse hold
            if state != .neutral {
                currentMax = max(currentMax, currentValue)
            }
            
            // Calcula progresso baseado no tempo
            let timeHeld = Date().timeIntervalSince(lastChangeTime)
            progress = min(CGFloat(timeHeld / holdDuration), 1.0)
            
            // Sucesso!
            if progress >= 1.0 {
                completeStep()
            }
            
        } else {
            // Usuário soltou o rosto antes da hora
            isHolding = false
            progress = 0.0
            // Não zeramos currentMax aqui, pois queremos o pico do melhor "hold" anterior se ele falhar
        }
    }
    
    private func completeStep() {
        // Feedback Tátil (Sucesso)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Salva e Avança
        switch state {
        case .neutral:
            // No futuro, podemos usar a média do neutral como "deadzone"
            // Por enquanto, apenas garante que o rosto foi detectado
            state = .smileLeft
            
        case .smileLeft:
            faceManager.setCalibrationMax(for: .smileLeft, value: currentMax)
            state = .smileRight
            
        case .smileRight:
            faceManager.setCalibrationMax(for: .smileRight, value: currentMax)
            state = .pucker
            
        case .pucker:
            faceManager.setCalibrationMax(for: .pucker, value: currentMax)
            state = .finished
            // Pequeno delay para mostrar conclusão antes de sair
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onCalibrationComplete()
            }
            
        case .finished:
            break
        }
        
        // Reset para próximo passo
        currentMax = 0.0
        progress = 0.0
        isHolding = false
        lastChangeTime = Date()
    }
    
    // MARK: - Helpers
    private func getCurrentMetricValue() -> Float {
        switch state {
        case .neutral:
            // No neutral, "progresso" é apenas tempo passando com o rosto detectado.
            // Retorna 1.0 fixo para encher a barra por tempo se o tracking estiver ativo.
            // Se quiser validar repouso: return 1.0 - (smileL + smileR + pucker)
            return 1.0
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

// Componente Visual Pequeno para os passos
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
