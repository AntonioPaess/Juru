import SwiftUI
import AVFoundation

struct MainTypingView: View {
    @Bindable var vocabManager: VocabularyManager
    var faceManager: FaceTrackingManager
    
    // Animação de background suave
    @State private var animateGradient = false
    
    // O "Motor" que faz a lógica rodar
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // 1. Background Dinâmico (Ambiental)
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.05, blue: 0.2)],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 10).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
            
            VStack(spacing: 20) {
                // 2. Barra Superior (Ações Rápidas)
                HStack {
                    Button(action: { /* Configs Action */ }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    // Indicador de Status do Rosto
                    HStack(spacing: 4) {
                        Circle()
                            .fill(faceManager.isTriggeringLeft ? Color.cyan : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(faceManager.isTriggeringRight ? Color.pink : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(faceManager.isTriggeringBack ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    .padding(8)
                    .background(.ultraThinMaterial, in: Capsule())
                    
                    Spacer()
                    
                    Button(action: {
                        vocabManager.currentMessage = ""
                        vocabManager.suggestions = []
                    }) {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundStyle(.red.opacity(0.8))
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // 3. Área de Texto (Display)
                VStack(alignment: .leading) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(vocabManager.currentMessage.isEmpty ? "Start typing..." : vocabManager.currentMessage)
                                .font(.system(size: 32, weight: .medium, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .id("bottom")
                        }
                        .onChange(of: vocabManager.currentMessage) {
                            withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                        }
                    }
                }
                .frame(height: 150)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal)
                
                // Botão de Falar (Destaque)
                if !vocabManager.currentMessage.isEmpty {
                    Button(action: { vocabManager.speakCurrentMessage() }) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("Speak")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .cornerRadius(30)
                        .shadow(color: .blue.opacity(0.5), radius: 10)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
                
                // 4. Área de Input (Zonas Ativas)
                HStack(spacing: 16) {
                    // Zona Esquerda
                    TypingZoneCard(
                        text: vocabManager.leftLabel,
                        isActive: faceManager.isTriggeringLeft,
                        color: .cyan,
                        alignment: .leading
                    )
                    
                    // Separador Central (Decorativo)
                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, .white.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                        .frame(width: 1)
                        .frame(maxHeight: 100)
                    
                    // Zona Direita
                    TypingZoneCard(
                        text: vocabManager.rightLabel,
                        isActive: faceManager.isTriggeringRight,
                        color: .pink,
                        alignment: .trailing
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // Dica de "Voltar" (Rodapé)
                Text("Pucker/Kiss to Undo or Go Back")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom)
                    .opacity(faceManager.isTriggeringBack ? 1.0 : 0.5)
                    .scaleEffect(faceManager.isTriggeringBack ? 1.1 : 1.0)
                    .animation(.spring, value: faceManager.isTriggeringBack)
            }
        }
        // ESTA É A PEÇA QUE FALTAVA:
        .onReceive(timer) { _ in
            vocabManager.update()
        }
    }
}

// Componente Visual das Zonas
struct TypingZoneCard: View {
    let text: String
    let isActive: Bool
    let color: Color
    let alignment: Alignment
    
    var body: some View {
        ZStack(alignment: alignment) {
            // Background Ativo
            RoundedRectangle(cornerRadius: 24)
                .fill(isActive ? AnyShapeStyle(color.opacity(0.2)) : AnyShapeStyle(.ultraThinMaterial))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isActive ? color : .white.opacity(0.1), lineWidth: isActive ? 3 : 1)
                )
                .shadow(color: isActive ? color.opacity(0.6) : .clear, radius: 20)
            
            // Conteúdo
            Text(text)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(isActive ? .white : .white.opacity(0.8))
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(isActive ? 1.05 : 1.0)
        }
        .frame(height: 180)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
        .animation(.smooth, value: text)
    }
}
