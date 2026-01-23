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
        case silence = 0    // O Problema
        case roots          // A Origem (Raízes -> Texto)
        case reveal         // A Revelação (Folhagem -> Logo)
        case demoNav        // Demo Navegação
        case demoPucker     // Demo Seleção
        case ready          // Calibração
    }
    
    @State private var currentPhase: Phase = .silence
    
    var body: some View {
        ZStack {
            AmbientBackground().ignoresSafeArea()
            
            VStack(spacing: 0) {
                // --- PALCO VISUAL ---
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
                .padding(.top, 40)
                
                // --- TEXTO E CONTROLES ---
                VStack(spacing: 36) {
                    VStack(spacing: 16) {
                        Text(titleText)
                            .font(.juruFont(.largeTitle, weight: .heavy))
                            .foregroundStyle(Color.juruText)
                            .multilineTextAlignment(.center)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .id("T\(currentPhase.rawValue)")
                        
                        Text(subtitleText)
                            .font(.juruFont(.title3, weight: .medium))
                            .foregroundStyle(Color.juruSecondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 32)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .id("S\(currentPhase.rawValue)")
                    }
                    
                    // Indicadores
                    HStack(spacing: 10) {
                        ForEach(Phase.allCases, id: \.self) { p in
                            Circle()
                                .fill(p == currentPhase ? Color.juruTeal : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(p == currentPhase ? 1.5 : 1.0)
                                .animation(.spring, value: currentPhase)
                        }
                    }
                    
                    // Botão
                    Button(action: nextPhase) {
                        Text(currentPhase == .ready ? "Begin Calibration" : "Continue")
                            .font(.juruFont(.headline, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                LinearGradient(colors: [.juruTeal, .juruTeal.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                            )
                            .clipShape(Capsule())
                            .shadow(color: .juruTeal.opacity(0.4), radius: 20, y: 10)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 60)
                .background(
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
    
    var titleText: String {
        switch currentPhase {
        case .silence: return "The Silent Forest"
        case .roots: return "Ancestral Roots"
        case .reveal: return "The Smile-Seed"
        case .demoNav: return "The Flow"
        case .demoPucker: return "The Voice"
        case .ready: return "Awaken Juru"
        }
    }
    
    var subtitleText: String {
        switch currentPhase {
        case .silence:
            return "Paralysis is like a forest without birdsong.\nThe mind is vibrant, alive, and full of color,\nbut the voice remains trapped within."
        case .roots:
            return "Deep in the Amazon, the Tupi people call the mouth 'Juru'.\nIt is more than a body part—it is the sacred gateway of the soul."
        case .reveal:
            return "Like a seed sprouting from the rich earth, a smile represents new life.\nThis symbol combines nature's growth with the curve of your joy."
        case .demoNav:
            return "Raise your eyebrows to guide the focus.\nLike a river flowing, the highlight moves to where you intend."
        case .demoPucker:
            return "A simple kiss (Pucker) breaks the silence.\nHold to select (Green). Hold longer to undo (Red)."
        case .ready:
            return "Juru needs to learn the unique map of your face.\nRelax, breathe, and let's connect."
        }
    }
}

// MARK: - Scene 1: The Silent Forest
struct SilenceScene: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            HStack(spacing: 20) {
                ForEach(0..<8) { i in
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 4, height: CGFloat.random(in: 100...300))
                }
            }
            
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.juruText.opacity(0.5))
                .frame(width: 200, height: 2)
                .overlay(
                    Circle()
                        .stroke(Color.juruText.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .scaleEffect(animate ? 1.5 : 0.5)
                        .opacity(animate ? 0.0 : 0.5)
                        .animation(.easeOut(duration: 3.0).repeatForever(autoreverses: false), value: animate)
                )
        }
        .onAppear { animate = true }
    }
}

// MARK: - Scene 2: Ancestral Roots (Corrigido: Raízes somem, Texto aparece)
struct RootsScene: View {
    @State private var grow = false
    @State private var showText = false
    
    var body: some View {
        ZStack {
            // As Vinhas (Agora desvanecem quando o texto aparece)
            ZStack {
                ForEach(0..<5) { i in
                    VineShape()
                        .trim(from: 0, to: grow ? 1 : 0)
                        .stroke(
                            LinearGradient(colors: [.juruTeal, .green.opacity(0.5)], startPoint: .bottom, endPoint: .top),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 120, height: 240)
                        .rotationEffect(.degrees(Double(i) * 72))
                        .opacity(showText ? 0.15 : 1.0) // Ficam transparentes
                        .animation(.easeInOut(duration: 2.0).delay(Double(i) * 0.2), value: grow)
                        .animation(.easeInOut(duration: 1.5), value: showText)
                }
            }
            
            // O Texto (Surge depois)
            Text("JURU")
                .font(.system(size: 70, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.juruTeal, .juruTeal.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: .juruTeal.opacity(0.3), radius: 20)
                .scaleEffect(showText ? 1.0 : 0.8)
                .opacity(showText ? 1.0 : 0.0)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(1.5), value: showText)
        }
        .onAppear {
            grow = true
            // Dispara a troca de foco após as vinhas crescerem
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showText = true
            }
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

// MARK: - Scene 3: The Amazon Reveal (Corrigido: Imersão na Floresta)
struct AmazonRevealScene: View {
    @State private var openJungle = false
    
    var body: some View {
        ZStack {
            // CAMADA 1: A Logo (Semente/Berço)
            // Surge do fundo
            Image("Juru-White")
                .resizable()
                .scaledToFit()
                .frame(width: 180)
                .shadow(color: .juruTeal.opacity(0.6), radius: 30)
                .scaleEffect(openJungle ? 1.0 : 0.4)
                .offset(y: openJungle ? 0 : 50)
                .opacity(openJungle ? 1.0 : 0.0)
                .animation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.2), value: openJungle)
            
            // CAMADA 2: Folhas de Fundo (O Berço)
            ZStack {
                LeafShape() // Esquerda Fundo
                    .fill(Color.juruTeal.opacity(0.1))
                    .frame(width: 200, height: 300)
                    .rotationEffect(.degrees(-20))
                    .offset(x: -80, y: 20)
                
                LeafShape() // Direita Fundo
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 200, height: 300)
                    .rotationEffect(.degrees(20))
                    .scaleEffect(x: -1, y: 1)
                    .offset(x: 80, y: 40)
            }
            .scaleEffect(openJungle ? 1.1 : 0.9) // Efeito de respiração
            .opacity(openJungle ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 2.0), value: openJungle)
            
            // CAMADA 3: Folhas da Frente (O Obstáculo que se abre)
            // Efeito "Andando pela mata"
            ZStack {
                // Folha Grande Esquerda
                LeafShape()
                    .fill(LinearGradient(colors: [.green, .juruTeal], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 300, height: 500)
                    .rotationEffect(.degrees(-15))
                    .offset(x: openJungle ? -400 : -100, y: openJungle ? 50 : 100) // Move para fora
                    .opacity(openJungle ? 0.0 : 1.0) // E some
                    .blur(radius: 4) // Profundidade de campo (perto da câmera)
                
                // Folha Grande Direita
                LeafShape()
                    .fill(LinearGradient(colors: [.juruTeal, .green], startPoint: .topTrailing, endPoint: .bottomLeading))
                    .frame(width: 300, height: 500)
                    .rotationEffect(.degrees(15))
                    .scaleEffect(x: -1, y: 1)
                    .offset(x: openJungle ? 400 : 100, y: openJungle ? -50 : 150) // Move para fora
                    .opacity(openJungle ? 0.0 : 1.0)
                    .blur(radius: 4)
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

// MARK: - Tech Demos (Mantidos Perfeitos)
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
            .background(RoundedRectangle(cornerRadius: 16).fill(isActive ? Color.juruTeal : Color.gray.opacity(0.1)))
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
        } else if phase == .demoPucker {
            let cycle = time.truncatingRemainder(dividingBy: 5.0)
            if cycle < 0.5 { demoPucker = 0; puckerProgress = 0 }
            else if cycle < 3.5 {
                withAnimation(.spring) { demoPucker = 1.0 }
                let holdTime = cycle - 0.5
                if holdTime < 1.0 { puckerColor = .juruTeal; puckerProgress = holdTime / 0.8 }
                else { puckerColor = .red; puckerProgress = min(1.0, 0.4 + (holdTime - 1.0) * 0.4) }
            } else { withAnimation(.spring) { demoPucker = 0.0 }; puckerProgress = 0 }
        }
    }
}

// MARK: - Scene Final
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
