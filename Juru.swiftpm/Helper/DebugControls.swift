//
//  DebugControls.swift
//  Juru
//
//  Created by Juru Debugger.
//

import SwiftUI

struct DebugControls: View {
    var faceManager: FaceTrackingManager
    // Closure para avisar a RootView que queremos pular
    var onSkip: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Grupo de Simulação de Gestos
            HStack(spacing: 12) {
                Button {
                    triggerGesture(.smileLeft)
                } label: {
                    Image(systemName: "arrow.left")
                        .bold()
                }
                .tint(.juruTeal)
                
                Button {
                    triggerGesture(.pucker)
                } label: {
                    Image(systemName: "mouth")
                        .bold()
                }
                .tint(.gray)
                
                Button {
                    triggerGesture(.smileRight)
                } label: {
                    Image(systemName: "arrow.right")
                        .bold()
                }
                .tint(.juruCoral)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Divider()
                .frame(height: 30)
            
            // Botão de Pular Calibração
            Button(action: onSkip) {
                Label("Skip Setup", systemImage: "forward.end.fill")
                    .font(.caption.bold())
            }
            .buttonStyle(.bordered)
            .tint(.primary)
            .background(.thinMaterial)
            .cornerRadius(8)
        }
        .padding(16)
        .background(.regularMaterial)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.1), radius: 15, y: 5)
        .padding(.bottom, 40)
    }
    
    func triggerGesture(_ gesture: FaceGesture) {
        // Simula o gesto ativo
        withAnimation {
            faceManager.currentValues[gesture] = 1.0
        }
        
        // Desativa após 0.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                faceManager.currentValues[gesture] = 0.0
            }
        }
    }
}
