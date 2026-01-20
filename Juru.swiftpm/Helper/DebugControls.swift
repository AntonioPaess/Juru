//
//  DebugControls.swift
//  Juru
//
//  Created by Juru Debugger.
//

import SwiftUI

struct DebugControls: View {
    var faceManager: FaceTrackingManager
    
    // Callbacks
    var onSkipAll: () -> Void
    var onStartTutorial: () -> Void
    var onMinimize: () -> Void // NOVO: Ação de minimizar
    
    var body: some View {
        VStack(spacing: 12) {
            
            // 0. Header (Título + Fechar)
            HStack {
                Text("DEBUGGER")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: onMinimize) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.secondary.opacity(0.5))
                }
            }
            .padding(.bottom, 4)
            
            // 1. Simulação de Gestos
            HStack(spacing: 12) {
                Button { triggerGesture(.smileLeft) } label: {
                    Image(systemName: "arrow.left").bold()
                }
                .tint(.juruTeal)
                
                Button { triggerGesture(.smileRight) } label: {
                    Image(systemName: "arrow.right").bold()
                }
                .tint(.juruCoral)
                
                Button { triggerGesture(.pucker) } label: {
                    Image(systemName: "mouth").bold()
                }
                .tint(.juruGold)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Divider()
            
            // 2. Navegação
            HStack {
                Button(action: onStartTutorial) {
                    Label("Tutorial", systemImage: "graduationcap.fill")
                        .font(.caption.bold())
                }
                .tint(.indigo)
                
                Button(action: onSkipAll) {
                    Label("App", systemImage: "forward.end.fill")
                        .font(.caption.bold())
                }
                .tint(.gray)
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .background(.regularMaterial)
        .cornerRadius(24)
        .shadow(radius: 10)
        .frame(maxWidth: 400) // Limita largura no iPad
    }
    
    func triggerGesture(_ gesture: FaceGesture) {
        withAnimation { faceManager.currentValues[gesture] = 1.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation { faceManager.currentValues[gesture] = 0.0 }
        }
    }
}
