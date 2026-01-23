////
////  DebugControls.swift
////  Juru
////
////  Created by Juru Debugger.
////
//
//import SwiftUI
//
//struct DebugControls: View {
//    @Bindable var faceManager: FaceTrackingManager
//    @Binding var isVisible: Bool
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            // Header
//            HStack {
//                Text("Debug Studio")
//                    .font(.headline)
//                    .foregroundStyle(.white)
//                Spacer()
//                Button { isVisible = false } label: {
//                    Image(systemName: "xmark.circle.fill")
//                        .foregroundStyle(.white.opacity(0.6))
//                        .font(.title2)
//                }
//            }
//            .padding(.bottom, 10)
//            
//            // --- BROW CONTROL (NAVEGAÇÃO) ---
//            VStack(alignment: .leading, spacing: 5) {
//                HStack {
//                    Text("Brow Up (Nav)")
//                        .font(.caption.bold())
//                        .foregroundStyle(Color.juruTeal)
//                    Spacer()
//                    Text(String(format: "%.2f", faceManager.browUp))
//                        .font(.caption.monospaced())
//                        .foregroundStyle(.white.opacity(0.8))
//                }
//                
//                Slider(
//                    value: Binding(
//                        get: { faceManager.browUp },
//                        set: { val in
//                            // Simula a injeção de valor no dicionário de valores atuais
//                            faceManager.currentValues[.browUp] = val
//                            // Força a atualização da lógica chamando o update manual se necessário
//                            // Nota: No código real, o update é chamado pelo ARKit.
//                            // Aqui estamos apenas atualizando o valor para visualização ou teste básico.
//                            // Para simular comportamento real, teríamos que chamar a lógica de trigger.
//                            simulateLogic()
//                        }
//                    ),
//                    in: 0...1.0
//                )
//                .tint(Color.juruTeal)
//            }
//            
//            // --- PUCKER CONTROL (AÇÃO) ---
//            VStack(alignment: .leading, spacing: 5) {
//                HStack {
//                    Text("Pucker (Select/Back)")
//                        .font(.caption.bold())
//                        .foregroundStyle(Color.juruCoral)
//                    Spacer()
//                    Text(String(format: "%.2f", faceManager.mouthPucker))
//                        .font(.caption.monospaced())
//                        .foregroundStyle(.white.opacity(0.8))
//                }
//                
//                Slider(
//                    value: Binding(
//                        get: { faceManager.mouthPucker },
//                        set: { val in
//                            faceManager.currentValues[.pucker] = val
//                            simulateLogic()
//                        }
//                    ),
//                    in: 0...1.0
//                )
//                .tint(Color.juruCoral)
//            }
//            
//            Divider().background(Color.white.opacity(0.2))
//            
//            // --- ESTADOS INTERNOS ---
//            HStack(spacing: 15) {
//                StateIndicator(label: "LEFT", isActive: faceManager.isTriggeringLeft, color: .juruTeal)
//                StateIndicator(label: "RIGHT", isActive: faceManager.isTriggeringRight, color: .juruCoral)
//                StateIndicator(label: "BACK", isActive: faceManager.isTriggeringBack, color: .red)
//            }
//            
//            // --- LONG PRESS PROGRESS ---
//            if faceManager.longPressProgress > 0 {
//                VStack(spacing: 4) {
//                    Text("Long Press: \(Int(faceManager.longPressProgress * 100))%")
//                        .font(.caption2)
//                        .foregroundStyle(.white.opacity(0.6))
//                    
//                    ProgressView(value: faceManager.longPressProgress)
//                        .progressViewStyle(LinearProgressViewStyle(tint: .red))
//                }
//            }
//        }
//        .padding(20)
//        .background(Color.black.opacity(0.85))
//        .clipShape(RoundedRectangle(cornerRadius: 20))
//        .overlay(
//            RoundedRectangle(cornerRadius: 20)
//                .stroke(Color.white.opacity(0.1), lineWidth: 1)
//        )
//        .padding()
//    }
//    
//    // Simula a lógica que normalmente estaria dentro do delegate do ARSession
//    // Isso permite testar a máquina de estados sem câmera
//    private func simulateLogic() {
//        Task { @MainActor in
//            // Copia da lógica de Trigger do FaceTrackingManager para simulação
//            _ = faceManager.browUp
//            let puckerVal = faceManager.mouthPucker
//            
//            // Navegação (Brow)
//            // Precisamos acessar as configs internas ou hardcodar para debug
//            let browThreshold = 0.4
//            
//            // A lógica original usa histerese com isBrowRelaxed
//            // Como variáveis privadas não são acessíveis facilmente aqui sem mudar o Manager,
//            // este DebugControls serve mais para VISUALIZAR e injetar valores brutos.
//            // Para um teste perfeito, o FaceTrackingManager deveria ter um método `processUpdate(brow:pucker:)`
//            // público que tanto o ARKit quanto este Debug chamam.
//            
//            // Mas para fins visuais de UI (SwiftUI Previews), setar os valores diretos já ajuda.
//        }
//    }
//}
//
//struct StateIndicator: View {
//    let label: String
//    let isActive: Bool
//    let color: Color
//    
//    var body: some View {
//        Text(label)
//            .font(.caption.bold())
//            .padding(.horizontal, 8)
//            .padding(.vertical, 4)
//            .background(isActive ? color : Color.white.opacity(0.1))
//            .foregroundStyle(isActive ? .white : .white.opacity(0.4))
//            .clipShape(Capsule())
//            .animation(.easeInOut, value: isActive)
//    }
//}
