//
//  OnboardingView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 04/01/26.
//

//
//  OnboardingView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 04/01/26.
//

import SwiftUI

struct OnboardingView: View {
    var faceManager: FaceTrackingManager
    var onFinished: () -> Void
    
    enum Phase: Int, CaseIterable {
        case silence = 0    // The Silent Forest (Paralysis)
        case roots          // Ancestral Roots (Tupi Culture)
        case reveal         // The Seed (Logo/Smile)
        case demoNav        // Navigation Demo
        case demoPuckerSelect // Selection Demo (Green)
        case demoPuckerUndo   // Undo Demo (Red)
        case ready          // Calibration Call
    }
    
    @State private var currentPhase: Phase = .silence
    
    var body: some View {
        ZStack {
            // Fundo Atmosférico que muda conforme a emoção da fase
            AmbientationBackground(phase: currentPhase).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // --- PALCO VISUAL (TOP) ---
                ZStack {
                    if currentPhase == .silence {
                        SilenceScene().transition(.opacity)
                    } else if currentPhase == .roots {
                        RootsScene().transition(.opacity)
                    } else if currentPhase == .reveal {
                        AmazonRevealScene().transition(.opacity)
                    } else if currentPhase == .ready {
                        AvatarCelebration(faceManager: faceManager).transition(.scale)
                    } else {
                        TechDemoScene(phase: currentPhase, faceManager: faceManager)
                            .transition(.opacity)
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.top, 60)
                
                // --- TEXTO E CONTROLES (BOTTOM) ---
                VStack(spacing: 36) {
                    VStack(spacing: 16) {
                        // Título Impactante
                        Text(titleText)
                            .font(.juruFont(.largeTitle, weight: .heavy))
                            .foregroundStyle(Color.juruText)
                            .multilineTextAlignment(.center)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .id("T\(currentPhase.rawValue)")
                        
                        // Subtítulo Poético
                        Text(subtitleText)
                            .font(.juruFont(.title3, weight: .medium))
                            .foregroundStyle(Color.juruSecondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6) // Melhora a leitura de textos longos
                            .padding(.horizontal, 32)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .id("S\(currentPhase.rawValue)")
                    }
                    
                    // Indicadores de Progresso (Sementes)
                    HStack(spacing: 12) {
                        ForEach(Phase.allCases, id: \.self) { p in
                            Circle()
                                .fill(p == currentPhase ? Color.juruTeal : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(p == currentPhase ? 1.5 : 1.0)
                                .animation(.spring, value: currentPhase)
                        }
                    }
                    
                    // Botão de Ação
                    Button(action: nextPhase) {
                        Text(currentPhase == .ready ? "Begin Calibration" : "Continue")
                            .font(.juruFont(.headline, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                LinearGradient(
                                    colors: [.juruTeal, .juruTeal.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .juruTeal.opacity(0.4), radius: 20, y: 10)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 60)
                .background(
                    // Vidro Fosco para garantir legibilidade sobre qualquer fundo
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(LinearGradient(colors: [.clear, .black, .black], startPoint: .top, endPoint: .bottom))
                        .ignoresSafeArea()
                        .padding(.top, -100)
                )
            }
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: currentPhase)
    }
    
    func nextPhase() {
        if currentPhase == .ready {
            onFinished()
        } else {
            if let next = Phase(rawValue: currentPhase.rawValue + 1) {
                currentPhase = next
            }
        }
    }
    
    // MARK: - Storytelling Text
    var titleText: String {
        switch currentPhase {
        case .silence: return "The Silent Forest"
        case .roots: return "Ancestral Roots"
        case .reveal: return "The Smile-Seed"
        case .demoNav: return "The Flow"
        case .demoPuckerSelect: return "The Choice"
        case .demoPuckerUndo: return "The Return"
        case .ready: return "Awaken Juru"
        }
    }
    
    var subtitleText: String {
        switch currentPhase {
        case .silence:
            return "Paralysis can feel like a forest without birdsong. Your mind is still alive and vibrant—but your voice is caught beneath the canopy."
        case .roots:
            return "We turned to ancestral wisdom. In Tupi, Juru means Mouth—not just anatomy, but the sacred gateway of the soul."
        case .reveal:
            return "Our symbol is a seed shaped like a smile. Planted in silence and nourished by technology, it blooms into your voice."
        case .demoNav:
            return "Your brows are the compass. Raise them to move focus, flowing smoothly through your options."
        case .demoPuckerSelect:
            return "A simple kiss becomes a command. Hold Pucker for 1s until the circle fills green to Select."
        case .demoPuckerUndo:
            return "Changed your mind? Keep holding for 2s until the circle turns red to Undo."
        case .ready:
            return "Every face is unique. Relax, breathe, and let Juru learn the map of your expressions."
        }
    }
}

// MARK: - Visual Scenes

// Scene 1: The Silent Forest (Darker, Melancholic but Hopeful)
struct SilenceScene: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Árvores abstratas (Estáticas)
            HStack(spacing: 20) {
                ForEach(0..<8) { i in
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 4, height: CGFloat.random(in: 100...300))
                }
            }
            
            // Onda Sonora "Morta" (Linha Reta)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.juruText.opacity(0.5))
                .frame(width: 200, height: 2)
                .overlay(
                    // O Pulso da Mente (Vibrante mas contido)
                    Circle()
                        .stroke(Color.juruTeal.opacity(0.5), lineWidth: 2)
                        .frame(width: 40, height: 40)
                        .scaleEffect(animate ? 1.5 : 0.5)
                        .opacity(animate ? 0.0 : 0.8)
                        .animation(.easeOut(duration: 3.0).repeatForever(autoreverses: false), value: animate)
                )
        }
        .onAppear { animate = true }
    }
}

// Scene 2: Ancestral Roots (Organic Growth)
struct RootsScene: View {
    @State private var grow = false
    @State private var showText = false
    
    var body: some View {
        ZStack {
            // Vinhas crescendo
            ZStack {
                ForEach(0..<5) { i in
                    VineShape()
                        .trim(from: 0, to: grow ? 1 : 0)
                        .stroke(
                            LinearGradient(colors: [.juruTeal, .green.opacity(0.6)], startPoint: .bottom, endPoint: .top),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 120, height: 240)
                        .rotationEffect(.degrees(Double(i) * 72))
                        .opacity(showText ? 0.2 : 1.0) // Fade out para dar destaque ao texto
                        .animation(.easeInOut(duration: 2.0).delay(Double(i) * 0.2), value: grow)
                        .animation(.easeInOut(duration: 1.5), value: showText)
                }
            }
            
            // A Palavra JURU surgindo
            Text("JURU")
                .font(.system(size: 70, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.juruTeal, .juruTeal.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: .juruTeal.opacity(0.4), radius: 20)
                .scaleEffect(showText ? 1.0 : 0.8)
                .opacity(showText ? 1.0 : 0.0)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(1.5), value: showText)
        }
        .onAppear {
            grow = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showText = true }
        }
    }
    
    struct VineShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addCurve(
                to: CGPoint(x: rect.midX, y: rect.minY),
                control1: CGPoint(x: rect.maxX, y: rect.midY),
                control2: CGPoint(x: rect.minX, y: rect.midY)
            )
            return path
        }
    }
}

// Scene 3: The Amazon Reveal (Foliage & Logo)
struct AmazonRevealScene: View {
    @State private var openJungle = false
    
    var body: some View {
        ZStack {
            // A Logo (O Tesouro/Semente)
            Image("Juru-White")
                .resizable()
                .scaledToFit()
                .frame(width: 180)
                .shadow(color: .juruTeal.opacity(0.8), radius: 40) // Glow forte
                .scaleEffect(openJungle ? 1.0 : 0.4)
                .offset(y: openJungle ? 0 : 50)
                .opacity(openJungle ? 1.0 : 0.0)
                .animation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.3), value: openJungle)
            
            // Camadas de Folhas (Efeito Parallax ao abrir)
            ZStack {
                // Folha Esquerda (Frente)
                LeafShape()
                    .fill(LinearGradient(colors: [.green, .juruTeal], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 300, height: 500)
                    .rotationEffect(.degrees(-15))
                    .offset(x: openJungle ? -450 : -100, y: openJungle ? 100 : 100)
                    .opacity(openJungle ? 0.0 : 1.0)
                    .blur(radius: 5) // Desfoque de profundidade
                
                // Folha Direita (Frente)
                LeafShape()
                    .fill(LinearGradient(colors: [.juruTeal, .green], startPoint: .topTrailing, endPoint: .bottomLeading))
                    .frame(width: 300, height: 500)
                    .rotationEffect(.degrees(15))
                    .scaleEffect(x: -1, y: 1)
                    .offset(x: openJungle ? 450 : 100, y: openJungle ? -100 : 150)
                    .opacity(openJungle ? 0.0 : 1.0)
                    .blur(radius: 5)
            }
            .animation(.easeInOut(duration: 1.8), value: openJungle)
        }
        .onAppear { openJungle = true }
    }
    
    struct LeafShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
            return path
        }
    }
}

// Scene 4 & 5 & 6: Tech Demos (Synchronized)
struct TechDemoScene: View {
    var phase: OnboardingView.Phase
    var faceManager: FaceTrackingManager
    
    @State private var demoBrow: Double = 0.0
    @State private var demoPucker: Double = 0.0
    @State private var activeIndex: Int = 0
    @State private var puckerProgress: Double = 0.0
    @State private var puckerColor: Color = .juruTeal
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @State private var time: Double = 0.0
    
    var body: some View {
        HStack(spacing: 50) {
            // UI Mock
            VStack(spacing: 20) {
                if phase == .demoNav {
                    GlassCard(icon: "hand.wave", label: "Hello", isActive: activeIndex == 0)
                    GlassCard(icon: "bolt.heart", label: "Pain", isActive: activeIndex == 1)
                } else {
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 8)
                        Circle().trim(from: 0, to: puckerProgress)
                            .stroke(puckerColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Image(systemName: puckerColor == .red ? "arrow.uturn.backward" : "checkmark")
                            .font(.largeTitle.bold()).foregroundStyle(puckerColor)
                            .opacity(puckerProgress > 0.1 ? 1 : 0.3)
                            .scaleEffect(puckerProgress > 0.1 ? 1.2 : 1.0)
                    }
                    .frame(width: 120, height: 120)
                }
            }
            .frame(width: 140)
            
            // Avatar
            JuruAvatarView(
                faceManager: faceManager,
                manualBrowUp: demoBrow,
                manualPucker: demoPucker,
                size: 180
            )
        }
        .onAppear { reset() }
        .onChange(of: phase) { reset() }
        .onReceive(timer) { _ in update() }
    }
    
    struct GlassCard: View {
        let icon: String; let label: String; let isActive: Bool
        var body: some View {
            HStack {
                Image(systemName: icon)
                Text(label).font(.headline.bold())
            }
            .foregroundStyle(isActive ? .white : .primary.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive ? Color.juruTeal : Color.gray.opacity(0.1))
            )
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isActive ? .white.opacity(0.5) : .clear, lineWidth: 1))
            .shadow(color: isActive ? Color.juruTeal.opacity(0.4) : .clear, radius: 10)
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isActive)
        }
    }
    
    func reset() { time = 0; demoBrow = 0; demoPucker = 0; activeIndex = 0; puckerProgress = 0 }
    
    func update() {
        time += 0.05
        if phase == .demoNav {
            let cycle = time.truncatingRemainder(dividingBy: 3.0)
            if cycle < 1.0 { demoBrow = 0 }
            else if cycle < 2.0 {
                withAnimation(.spring(response: 0.3)) { demoBrow = 1.0 }
                if cycle >= 1.0 && cycle < 1.05 { withAnimation { activeIndex = (activeIndex == 0 ? 1 : 0) } }
            } else { withAnimation(.spring(response: 0.4)) { demoBrow = 0.0 } }
        } else if phase == .demoPuckerSelect {
            // Animação de Seleção (Verde)
            let cycle = time.truncatingRemainder(dividingBy: 3.0)
            if cycle < 0.5 {
                demoPucker = 0; puckerProgress = 0
            } else if cycle < 2.0 {
                // Segura por 1.5s (simulando o select)
                withAnimation(.spring) { demoPucker = 1.0 }
                let holdTime = cycle - 0.5
                // Enche até o verde e para
                if holdTime < 1.2 {
                    puckerColor = .juruTeal
                    puckerProgress = holdTime / 1.0 // 1s para encher
                } else {
                    puckerProgress = 1.0
                }
            } else {
                withAnimation(.spring) { demoPucker = 0.0 }; puckerProgress = 0
            }
        } else if phase == .demoPuckerUndo {
            // Animação de Undo (Vermelho)
            let cycle = time.truncatingRemainder(dividingBy: 4.5)
            if cycle < 0.5 {
                demoPucker = 0; puckerProgress = 0
            } else if cycle < 3.5 {
                withAnimation(.spring) { demoPucker = 1.0 }
                let holdTime = cycle - 0.5
                
                // Passa pelo verde...
                if holdTime < 1.2 {
                    puckerColor = .juruTeal
                    puckerProgress = holdTime / 1.0
                } else {
                    // ...e vai para o vermelho
                    puckerColor = .red
                    // Preenche o resto (supondo mais 1s ou mais para o undo)
                    puckerProgress = min(1.0, 0.4 + (holdTime - 1.2) * 0.4) // Ajuste visual
                }
            } else {
                withAnimation(.spring) { demoPucker = 0.0 }; puckerProgress = 0
            }
        }
    }
}

// Scene 7: Avatar Celebration
struct AvatarCelebration: View {
    var faceManager: FaceTrackingManager
    @State private var dance = false
    var body: some View {
        JuruAvatarView(
            faceManager: faceManager,
            manualBrowUp: dance ? 0.3 : 0.0,
            manualPucker: dance ? 0.5 : 0.0,
            size: 240
        )
        .rotationEffect(.degrees(dance ? 5 : -5))
        .scaleEffect(dance ? 1.1 : 1.0)
        .onAppear { withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { dance = true } }
    }
}

// MARK: - Ambient Background
struct AmbientationBackground: View {
    var phase: OnboardingView.Phase
    
    var body: some View {
        ZStack {
            Color.juruBackground
            
            GeometryReader { proxy in
                // Círculo Superior
                Circle()
                    .fill(topColor)
                    .frame(width: 500)
                    .blur(radius: 100)
                    .offset(x: -100, y: -150)
                
                // Círculo Inferior
                Circle()
                    .fill(bottomColor)
                    .frame(width: 400)
                    .blur(radius: 80)
                    .position(x: proxy.size.width, y: proxy.size.height * 0.8)
            }
        }
        .animation(.easeInOut(duration: 1.5), value: phase)
    }
    
    var topColor: Color {
        switch phase {
        case .silence: return Color.gray.opacity(0.15)
        case .roots: return Color.green.opacity(0.2)
        case .reveal: return Color.juruTeal.opacity(0.25)
        default: return Color.juruTeal.opacity(0.15)
        }
    }
    
    var bottomColor: Color {
        switch phase {
        case .silence: return Color.black.opacity(0.2)
        case .roots: return Color.juruTeal.opacity(0.15)
        case .demoPuckerSelect: return Color.juruTeal.opacity(0.15)
        case .demoPuckerUndo: return Color.juruCoral.opacity(0.15)
        default: return Color.juruTeal.opacity(0.1)
        }
    }
}
