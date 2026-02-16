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
        case silence = 0
        case roots
        case reveal
        case demoNav
        case demoPuckerSelect
        case demoPuckerUndo
        case ready
    }
    
    @State private var currentPhase: Phase = .silence
    
    var body: some View {
        GeometryReader { geo in
            // Detecção de Orientação e Dispositivo
            let isLandscape = geo.size.width > geo.size.height
            let isPad = geo.size.width > 600
            
            // Ajuste fino de escala: Menor no Landscape para não estourar altura
            let scale = isPad ? (isLandscape ? 1.1 : 1.2) : 1.0
            
            ZStack {
                Color.juruBackground.ignoresSafeArea()
                
                // Fundo Atmosférico (Com correção de banding)
                AmbientOnboardingBackground(phase: currentPhase)
                    .ignoresSafeArea()
                    .drawingGroup()
                
                if isLandscape {
                    // --- LAYOUT IPAD (HORIZONTAL) ---
                    HStack(spacing: 0) {
                        // ESQUERDA: Conteúdo (Texto + Controles)
                        VStack(alignment: .center, spacing: 40 * scale) {
                            Spacer()
                            
                            // Bloco de Texto
                            OnboardingTextGroup(
                                phase: currentPhase,
                                title: titleText,
                                subtitle: subtitleText,
                                scale: scale
                            )
                            
                            // Bloco de Controles
                            VStack(spacing: 30 * scale) {
                                ProgressDots(currentPhase: currentPhase, scale: scale)
                                
                                ActionButton(
                                    title: currentPhase == .ready ? "Begin Calibration" : "Continue",
                                    scale: scale,
                                    action: nextPhase
                                )
                            }
                            
                            Spacer()
                        }
                        .frame(width: geo.size.width * 0.45) // 45% da tela
                        .padding(.leading, 60) // Margem esquerda
                        .zIndex(1)
                        
                        // DIREITA: Visual (Hero)
                        ZStack {
                            VisualStage(
                                phase: currentPhase,
                                faceManager: faceManager,
                                scale: scale * 1.1
                            )
                        }
                        .frame(width: geo.size.width * 0.55)
                        .padding(.trailing, 60) // <--- CORREÇÃO: Respiro na direita para não colar na parede
                    }
                } else {
                    // --- LAYOUT IPHONE/PORTRAIT (VERTICAL) ---
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // VISUAL (Topo)
                        VisualStage(
                            phase: currentPhase,
                            faceManager: faceManager,
                            scale: scale
                        )
                        .frame(height: geo.size.height * 0.45)
                        
                        // CONTEÚDO (Baixo)
                        VStack(alignment: .center, spacing: 30 * scale) {
                            OnboardingTextGroup(
                                phase: currentPhase,
                                title: titleText,
                                subtitle: subtitleText,
                                scale: scale
                            )
                            .padding(.horizontal, 24)
                            
                            VStack(spacing: 24 * scale) {
                                ProgressDots(currentPhase: currentPhase, scale: scale)
                                
                                ActionButton(
                                    title: currentPhase == .ready ? "Begin Calibration" : "Continue",
                                    scale: scale,
                                    action: nextPhase
                                )
                            }
                        }
                        .padding(.bottom, 50)
                        .padding(.top, 20)
                        .background(
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .mask(LinearGradient(colors: [.clear, .black, .black], startPoint: .top, endPoint: .bottom))
                                .ignoresSafeArea()
                                .padding(.top, -100)
                        )
                    }
                }
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
    
    // MARK: - Textos
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
            return "Paralysis is like a forest without birdsong. The mind remains a vibrant ecosystem, full of color and life, but the voice is trapped within the canopy."
        case .roots:
            return "We turned to the Amazon for answers. In the Tupi language, 'Juru' means Mouth—not just anatomy, but the sacred gateway of the soul."
        case .reveal:
            return "Our symbol is a seed shaped like a smile. Planted in silence and nourished by technology, it blooms into your new voice."
        case .demoNav:
            return "Your brows are the compass. Raise them to guide the focus, flowing like a river through your options."
        case .demoPuckerSelect:
            return "A simple kiss becomes a command. Hold Pucker for 1s until the circle fills green to Select."
        case .demoPuckerUndo:
            return "Changed your mind? Keep holding for 2s until the circle turns red to Undo."
        case .ready:
            return "Juru needs to learn the unique map of your face. Relax, breathe, and let's find your voice."
        }
    }
}

// MARK: - Componentes

struct OnboardingTextGroup: View {
    let phase: OnboardingView.Phase
    let title: String
    let subtitle: String
    let scale: CGFloat
    
    var body: some View {
        VStack(spacing: 20 * scale) {
            // TÍTULO
            Text(title)
                .font(.juruFont(.largeTitle, weight: .heavy))
                .scaleEffect(scale)
                .foregroundStyle(Color.juruText)
                .multilineTextAlignment(.center)
                .transition(.blurReplace)
                .id("T\(phase.rawValue)")
            
            // SUBTÍTULO
            Text(subtitle)
                .font(.system(size: 22 * scale, weight: .medium, design: .rounded))
                .foregroundStyle(Color.juruSecondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .transition(.opacity)
                .id("S\(phase.rawValue)")
        }
        .frame(maxWidth: 600 * scale)
    }
}

struct ProgressDots: View {
    let currentPhase: OnboardingView.Phase
    let scale: CGFloat
    
    var body: some View {
        HStack(spacing: 12 * scale) {
            ForEach(OnboardingView.Phase.allCases, id: \.self) { p in
                Circle()
                    .fill(p == currentPhase ? Color.juruTeal : Color.gray.opacity(0.3))
                    .frame(width: 10 * scale, height: 10 * scale)
                    .scaleEffect(p == currentPhase ? 1.3 : 1.0)
                    .animation(.spring, value: currentPhase)
            }
        }
        .padding(.top, 10)
    }
}

struct ActionButton: View {
    let title: String
    let scale: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20 * scale, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22 * scale)
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
        .frame(maxWidth: 380 * scale)
    }
}

struct VisualStage: View {
    let phase: OnboardingView.Phase
    var faceManager: FaceTrackingManager
    let scale: CGFloat
    
    var body: some View {
        ZStack {
            if phase == .silence {
                SilenceScene(scale: scale).transition(.opacity)
            } else if phase == .roots {
                RootsScene(scale: scale).transition(.opacity)
            } else if phase == .reveal {
                AmazonRevealScene(scale: scale).transition(.opacity)
            } else if phase == .ready {
                AvatarCelebration(faceManager: faceManager, scale: scale).transition(.scale)
            } else {
                TechDemoScene(phase: phase, faceManager: faceManager, scale: scale)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Visual Scenes

struct SilenceScene: View {
    var scale: CGFloat = 1.0
    @State private var animate = false
    
    var body: some View {
        ZStack {
            HStack(spacing: 20 * scale) {
                ForEach(0..<8) { i in
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 4 * scale, height: CGFloat.random(in: (100*scale)...(300*scale)))
                }
            }
            
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.juruText.opacity(0.5))
                .frame(width: 200 * scale, height: 2 * scale)
                .overlay(
                    Circle()
                        .stroke(Color.juruText.opacity(0.3))
                        .frame(width: 40 * scale, height: 40 * scale)
                        .scaleEffect(animate ? 1.5 : 0.5)
                        .opacity(animate ? 0.0 : 0.5)
                        .animation(.easeOut(duration: 3.0).repeatForever(autoreverses: false), value: animate)
                )
        }
        .onAppear { animate = true }
    }
}

struct RootsScene: View {
    var scale: CGFloat = 1.0
    @State private var grow = false
    @State private var showText = false
    
    var body: some View {
        ZStack {
            ZStack {
                ForEach(0..<5) { i in
                    VineShape()
                        .trim(from: 0, to: grow ? 1 : 0)
                        .stroke(
                            LinearGradient(colors: [.juruTeal, .green.opacity(0.6)], startPoint: .bottom, endPoint: .top),
                            style: StrokeStyle(lineWidth: 5 * scale, lineCap: .round)
                        )
                        .frame(width: 120 * scale, height: 240 * scale)
                        .rotationEffect(.degrees(Double(i) * 72))
                        .opacity(showText ? 0.15 : 1.0)
                        .animation(.easeInOut(duration: 2.0).delay(Double(i) * 0.2), value: grow)
                        .animation(.easeInOut(duration: 1.5), value: showText)
                }
            }
            
            Text("JURU")
                .font(.system(size: 70 * scale, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.juruTeal, .juruTeal.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: .juruTeal.opacity(0.3), radius: 20 * scale)
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
            path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY), control1: CGPoint(x: rect.maxX, y: rect.midY), control2: CGPoint(x: rect.minX, y: rect.midY))
            return path
        }
    }
}

struct AmazonRevealScene: View {
    var scale: CGFloat = 1.0
    @State private var openJungle = false
    
    var body: some View {
        ZStack {
            Image("Juru-White")
                .resizable()
                .scaledToFit()
                .frame(width: 180 * scale)
                .shadow(color: .juruTeal.opacity(0.8), radius: 40 * scale)
                .scaleEffect(openJungle ? 1.0 : 0.4)
                .offset(y: openJungle ? 0 : 50 * scale)
                .opacity(openJungle ? 1.0 : 0.0)
                .animation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.2), value: openJungle)
            
            ZStack {
                LeafShape()
                    .fill(LinearGradient(colors: [.green, .juruTeal], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 300 * scale, height: 500 * scale)
                    .rotationEffect(.degrees(-15))
                    .offset(x: openJungle ? -400 * scale : -100 * scale, y: openJungle ? 50 * scale : 100 * scale)
                    .opacity(openJungle ? 0.0 : 1.0)
                    .blur(radius: 5)
                
                LeafShape()
                    .fill(LinearGradient(colors: [.juruTeal, .green], startPoint: .topTrailing, endPoint: .bottomLeading))
                    .frame(width: 300 * scale, height: 500 * scale)
                    .rotationEffect(.degrees(15))
                    .scaleEffect(x: -1, y: 1)
                    .offset(x: openJungle ? 400 * scale : 100 * scale, y: openJungle ? -50 * scale : 150 * scale)
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

/// Animated demonstration scene showing facial gesture mechanics.
///
/// Displays different demos based on the current onboarding phase:
/// - **demoNav**: Shows eyebrow raise toggling between menu options
/// - **demoPuckerSelect**: Shows short pucker hold for selection (1.2s)
/// - **demoPuckerUndo**: Shows long pucker hold for undo action (2.0s)
///
/// ## Architecture
/// Uses `TimelineView` at 50ms intervals for smooth animation without memory leaks.
/// The avatar mirrors the demo gestures in real-time to teach users the interaction model.
struct TechDemoScene: View {
    var phase: OnboardingView.Phase
    var faceManager: FaceTrackingManager
    var scale: CGFloat = 1.0

    @State private var demoBrow: Double = 0.0
    @State private var demoPucker: Double = 0.0
    @State private var activeIndex: Int = 0
    @State private var puckerProgress: Double = 0.0
    @State private var puckerColor: Color = .juruTeal

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.05)) { timeline in
            HStack(spacing: 50 * scale) {
                VStack(spacing: 20 * scale) {
                    if phase == .demoNav {
                        GlassCard(icon: "hand.wave", label: "Hello", isActive: activeIndex == 0, scale: scale)
                        GlassCard(icon: "bolt.heart", label: "Pain", isActive: activeIndex == 1, scale: scale)
                    } else {
                        ZStack {
                            Circle().stroke(Color.white.opacity(0.1), lineWidth: 8 * scale)
                            Circle().trim(from: 0, to: puckerProgress)
                                .stroke(puckerColor, style: StrokeStyle(lineWidth: 8 * scale, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Image(systemName: puckerColor == .red ? "arrow.uturn.backward" : "checkmark")
                                .font(.system(size: 34 * scale, weight: .bold))
                                .foregroundStyle(puckerColor)
                                .opacity(puckerProgress > 0.1 ? 1 : 0.3)
                                .scaleEffect(puckerProgress > 0.1 ? 1.2 : 1.0)
                        }
                        .frame(width: 120 * scale, height: 120 * scale)
                    }
                }
                .frame(width: 140 * scale)

                JuruAvatarView(
                    faceManager: faceManager,
                    manualBrowUp: demoBrow,
                    manualPucker: demoPucker,
                    size: 180 * scale
                )
            }
            .onChange(of: timeline.date) { _, _ in
                update()
            }
        }
        .onAppear { reset() }
        .onChange(of: phase) { reset() }
    }

    /// A glassmorphic card component for menu option display
    struct GlassCard: View {
        let icon: String; let label: String; let isActive: Bool; let scale: CGFloat
        var body: some View {
            HStack {
                Image(systemName: icon)
                Text(label).font(.system(size: 17 * scale, weight: .bold))
            }
            .foregroundStyle(isActive ? .white : .primary.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16 * scale)
            .background(
                RoundedRectangle(cornerRadius: 16 * scale)
                    .fill(isActive ? Color.juruTeal : Color.gray.opacity(0.1))
            )
            .overlay(RoundedRectangle(cornerRadius: 16 * scale).stroke(isActive ? .white.opacity(0.5) : .clear, lineWidth: 1))
            .shadow(color: isActive ? Color.juruTeal.opacity(0.4) : .clear, radius: 10 * scale)
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isActive)
        }
    }
    
    func reset() { demoBrow = 0; demoPucker = 0; activeIndex = 0; puckerProgress = 0 }
    
    func update() {
        if phase == .demoNav {
            let cycle = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 3.0)
            if cycle < 1.0 { demoBrow = 0 }
            else if cycle < 2.0 {
                withAnimation(.spring(response: 0.3)) { demoBrow = 1.0 }
                if cycle >= 1.0 && cycle < 1.05 { withAnimation { activeIndex = (activeIndex == 0 ? 1 : 0) } }
            } else { withAnimation(.spring(response: 0.4)) { demoBrow = 0.0 } }
        } else if phase == .demoPuckerSelect {
            let cycle = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 3.0)
            if cycle < 0.5 { demoPucker = 0; puckerProgress = 0 }
            else if cycle < 2.0 {
                withAnimation(.spring) { demoPucker = 1.0 }
                let holdTime = cycle - 0.5
                if holdTime < 1.2 { puckerColor = .juruTeal; puckerProgress = holdTime / 1.0 }
                else { puckerProgress = 1.0 }
            } else { withAnimation(.spring) { demoPucker = 0.0 }; puckerProgress = 0 }
        } else if phase == .demoPuckerUndo {
            let cycle = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 4.5)
            if cycle < 0.5 { demoPucker = 0; puckerProgress = 0 }
            else if cycle < 3.5 {
                withAnimation(.spring) { demoPucker = 1.0 }
                let holdTime = cycle - 0.5
                if holdTime < 1.2 { puckerColor = .juruTeal; puckerProgress = holdTime / 1.0 }
                else { puckerColor = .red; puckerProgress = min(1.0, 0.4 + (holdTime - 1.2) * 0.4) }
            } else { withAnimation(.spring) { demoPucker = 0.0 }; puckerProgress = 0 }
        }
    }
}

struct AvatarCelebration: View {
    var faceManager: FaceTrackingManager
    var scale: CGFloat = 1.0
    @State private var dance = false
    var body: some View {
        JuruAvatarView(
            faceManager: faceManager,
            manualBrowUp: dance ? 0.3 : 0.0,
            manualPucker: dance ? 0.5 : 0.0,
            size: 240 * scale
        )
        .rotationEffect(.degrees(dance ? 5 : -5))
        .scaleEffect(dance ? 1.1 : 1.0)
        .onAppear { withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { dance = true } }
    }
}

struct AmbientOnboardingBackground: View {
    var phase: OnboardingView.Phase
    
    var body: some View {
        ZStack {
            Color.juruBackground
            GeometryReader { proxy in
                Circle()
                    .fill(topColor)
                    .frame(width: 500)
                    .blur(radius: 100)
                    .offset(x: -100, y: -150)
                
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
