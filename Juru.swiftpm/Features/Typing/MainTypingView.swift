import SwiftUI

struct MainTypingView: View {
    var vocabManager: VocabularyManager
    var faceManager: FaceTrackingManager
    
    var body: some View {
        ZStack {
            ARViewContainer(manager: faceManager)
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.6), .black.opacity(0.2), .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            VStack(spacing: 0) {
                // Área de Texto Principal
                VStack(alignment: .leading) {
                    Text(vocabManager.currentMessage.isEmpty ? "Smile left to start..." : vocabManager.currentMessage)
                        .font(.system(.largeTitle, design: .rounded)) // Padrão Apple: Dynamic Type
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .minimumScaleFactor(0.5) // Acessibilidade: Evita truncar texto grande
                        .animation(.default, value: vocabManager.currentMessage)
                    
                    if !vocabManager.currentMessage.isEmpty {
                        Capsule() // Cursor mais suave que Rectangle
                            .fill(Color.accentColor) // Usa a cor de acento do sistema/app
                            .frame(width: 4, height: 32)
                            .opacity(0.8)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial) // Padrão Apple: Glassmorphism real
                        .stroke(.white.opacity(0.2), lineWidth: 0.5)
                )
                .padding(.horizontal, 20)
                .padding(.top, 60)
            
                // Sugestões
                if !vocabManager.suggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(vocabManager.suggestions, id: \.self) { word in
                                Text(word)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial, in: Capsule()) // Pílula nativa
                                    .overlay(
                                        Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5)
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .frame(height: 50)
                    .padding(.top, 16)
                }
                
                Spacer()
                
                KeyboardView(vocabManager: vocabManager)
                    .padding(.bottom, 40)
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: faceManager.triggerHaptic)
        .onChange(of: faceManager.smileRight) { vocabManager.update() }
        .onChange(of: faceManager.smileLeft) { vocabManager.update() }
        .onChange(of: faceManager.mouthPucker) { vocabManager.update() }
    }
}
