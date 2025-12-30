import SwiftUI

struct CalibrationView: View {
    var faceManager: FaceTrackingManager
    var onCalibrationComplete: () -> Void
    
    enum CalibState { case neutral, smileLeft, smileRight, pucker, finished }
    @State private var state: CalibState = .neutral
    @State private var maxValue: Float = 0.0
    
    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Câmera Frame
                ZStack {
                    ARViewContainer(manager: faceManager)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous)) // Style continuous é mais "Apple"
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(.separator, lineWidth: 1) // Cor de separador nativa
                        )
                    
                    VStack {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("TRACKING_ACTIVE")
                                    .font(.caption2.monospaced().bold())
                                    .foregroundStyle(.secondary)
                                Text("60 FPS")
                                    .font(.caption2.monospaced().bold())
                                    .foregroundStyle(.cyan)
                            }
                            Spacer()
                        }
                        Spacer()
                    }.padding()
                }
                .frame(height: 350)
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Instruções
                Text(instructionText)
                    .font(.title3.weight(.medium)) // Tamanho semântico
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(height: 60)
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .scale)) // Animação suave na troca de texto
                    .id(state) // Força a animação na troca de estado
                
                // Barras de Progresso
                VStack(spacing: 25) {
                    HUDProgressBar(label: "MOUTH SMILE LEFT", value: Float(faceManager.smileLeft), color: .cyan, isActive: state == .smileLeft)
                    HUDProgressBar(label: "MOUTH SMILE RIGHT", value: Float(faceManager.smileRight), color: Color(red: 1.0, green: 0.27, blue: 0.23), isActive: state == .smileRight)
                    HUDProgressBar(label: "MOUTH PUCKER", value: Float(faceManager.mouthPucker), color: Color(red: 0.2, green: 0.84, blue: 0.29), isActive: state == .pucker)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                Spacer()
                
                // Botão Nativo Apple
                Button(action: nextStep) {
                    Text(buttonText)
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent) // Estilo moderno iOS
                .controlSize(.large) // Tamanho de botão principal
                .tint(.white) // Mantém o estilo "High Contrast" (Texto fica preto automático)
                .foregroundStyle(.black)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .onChange(of: faceManager.smileLeft) { _, new in if state == .smileLeft { maxValue = max(maxValue, Float(new)) } }
        .onChange(of: faceManager.smileRight) { _, new in if state == .smileRight { maxValue = max(maxValue, Float(new)) } }
        .onChange(of: faceManager.mouthPucker) { _, new in if state == .pucker { maxValue = max(maxValue, Float(new)) } }
    }
    
    // ... (restante das variáveis computed instructionText e buttonText permanecem iguais)
    var instructionText: String {
        switch state {
        case .neutral: return "Relax face to define neutral state."
        case .smileLeft: return "Smile to the LEFT."
        case .smileRight: return "Smile to the RIGHT."
        case .pucker: return "Make a PUCKER (Kiss)."
        case .finished: return "Calibration Complete."
        }
    }
    
    var buttonText: String { state == .finished ? "START APP" : "NEXT STEP" }
    
    func nextStep() {
        switch state {
        case .neutral: state = .smileLeft; maxValue = 0
        case .smileLeft: faceManager.setCalibrationMax(for: "smileLeft", value: maxValue); state = .smileRight; maxValue = 0
        case .smileRight: faceManager.setCalibrationMax(for: "smileRight", value: maxValue); state = .pucker; maxValue = 0
        case .pucker: faceManager.setCalibrationMax(for: "pucker", value: maxValue); state = .finished
        case .finished: onCalibrationComplete()
        }
    }
}
