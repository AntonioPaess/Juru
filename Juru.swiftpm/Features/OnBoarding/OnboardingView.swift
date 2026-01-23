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
        case problem = 0    // O Silêncio (ELA/Paralisia)
        case origin         // A Cultura (Raízes Tupi)
        case reveal         // A Semente (Logo Reveal)
        case demoBrows      // Navegação (Mantido)
        case demoPucker     // Seleção (Mantido)
        case ready          // Avatar Dançando (Mantido)
    }
    
    @State private var currentPhase: Phase = .problem
    
    var body: some View {
        ZStack {
            AmbientBackground().ignoresSafeArea()
            
            VStack(spacing: 0) {
                // --- PALCO VISUAL ---
                ZStack {
                    if currentPhase == .problem {
                        ProblemScene()
                            .transition(.opacity)
                    } else if currentPhase == .origin {
                        OriginScene()
                            .transition(.opacity)
                    } else if currentPhase == .reveal {
                        RevealScene()
                            .transition(.opacity)
                    } else if currentPhase == .ready {
                        AvatarCelebration(faceManager: faceManager)
                            .transition(.scale)
                    } else {
                        TechDemoScene(phase: currentPhase, faceManager: faceManager)
                            .transition(.opacity)
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.top, 60)
                
                // --- TEXTO E CONTROLES ---
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text(titleText)
                            .font(.juruFont(.largeTitle, weight: .heavy))
                            .foregroundStyle(Color.juruText)
                            .multilineTextAlignment(.center)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .id("Title-\(currentPhase.rawValue)")
                        
                        Text(subtitleText)
                            .font(.juruFont(.title3, weight: .medium))
                            .foregroundStyle(Color.juruSecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .id("Sub-\(currentPhase.rawValue)")
                    }
                    
                    // Indicadores
                    HStack(spacing: 8) {
                        ForEach(Phase.allCases, id: \.self) { p in
                            Capsule()
                                .fill(p == currentPhase ? Color.juruTeal : Color.gray.opacity(0.3))
                                .frame(width: p == currentPhase ? 32 : 8, height: 8)
                                .animation(.spring, value: currentPhase)
                        }
                    }
                    
                    // Botão
                    Button(action: nextPhase) {
                        Text(currentPhase == .ready ? "Start Calibration" : "Continue")
                            .font(.juruFont(.headline, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.juruTeal)
                            .clipShape(Capsule())
                            .shadow(color: .juruTeal.opacity(0.4), radius: 15, y: 5)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 60)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .center))
                        .ignoresSafeArea()
                        .padding(.top, -80)
                )
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentPhase)
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
        case .problem: return "The Silence"
        case .origin: return "The Roots"
        case .reveal: return "The Seed"
        case .demoBrows: return "You Lead"
        case .demoPucker: return "You Choose"
        case .ready: return "Juru is Yours"
        }
    }
    
    var subtitleText: String {
        switch currentPhase {
        case .problem:
            return "For millions with ALS and paralysis, the body becomes a cage.\nThe voice fades, but the mind remains vibrant."
        case .origin:
            return "We looked to the Amazon for answers.\nIn the Tupi language, 'Juru' means Mouth—the sacred portal of the soul."
        case .reveal:
            return "Like a seed sprouting, a smile represents new life.\nThis symbol combines nature's growth with the curve of your joy."
        case .demoBrows:
            return "Raise your eyebrows to switch focus.\nWatch the menu toggle between Blue and Red."
        case .demoPucker:
            return "Hold a kiss face (Pucker) to interact.\nGreen to Select. Long hold (Red) to Delete."
        case .ready:
            return "I need to learn your unique expressions.\nRelax your face, and let's begin."
        }
    }
}

// MARK: - Cena 1: O Silêncio (Problem)
struct ProblemScene: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Onda Sonora "Morrendo" (Ficando flat)
            HStack(spacing: 8) {
                ForEach(0..<15) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.juruText.opacity(0.3))
                        .frame(width: 8, height: animate ? 4 : CGFloat.random(in: 20...100))
                        .animation(
                            .easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(Double(i) * 0.1),
                            value: animate
                        )
                }
            }
            // Névoa
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 200, height: 200)
                .blur(radius: 40)
        }
        .onAppear { animate = true }
    }
}

// MARK: - Cena 2: A Origem (Roots)
struct OriginScene: View {
    @State private var grow = false
    
    var body: some View {
        ZStack {
            // Raízes crescendo (Formas orgânicas)
            ForEach(0..<4) { i in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.juruTeal.opacity(0.6), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 10, height: 200)
                    .scaleEffect(y: grow ? 1.0 : 0.0, anchor: .bottom)
                    .rotationEffect(.degrees(Double(i) * 30 - 45))
                    .offset(y: 40)
                    .animation(
                        .spring(response: 1.5, dampingFraction: 0.6).delay(Double(i) * 0.2),
                        value: grow
                    )
            }
            
            // Texto "Tupi" sutil
            Text("tupi")
                .font(.juruFont(.largeTitle, weight: .bold))
                .foregroundStyle(Color.juruTeal.opacity(0.2))
                .offset(y: -50)
                .blur(radius: grow ? 0 : 10)
                .opacity(grow ? 1 : 0)
                .animation(.easeIn(duration: 1.0).delay(0.5), value: grow)
        }
        .onAppear { grow = true }
    }
}

// MARK: - Cena 3: A Revelação (Reveal)
struct RevealScene: View {
    @State private var reveal = false
    
    var body: some View {
        ZStack {
            // A Logo (Semente/Sorriso)
            Image("Juru-White")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .shadow(color: .juruTeal.opacity(0.6), radius: 30)
                .scaleEffect(reveal ? 1.0 : 0.0)
                .rotationEffect(.degrees(reveal ? 0 : -180))
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3), value: reveal)
            
            // Folhas da Amazônia (Cobrindo e abrindo)
            ZStack {
                // Folha Esquerda
                LeafShape()
                    .fill(LinearGradient(colors: [.green, .juruTeal], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 150, height: 250)
                    .rotationEffect(.degrees(-30))
                    .offset(x: reveal ? -200 : -20, y: reveal ? -100 : 0)
                    .opacity(reveal ? 0 : 1)
                
                // Folha Direita
                LeafShape()
                    .fill(LinearGradient(colors: [.juruTeal, .green], startPoint: .topTrailing, endPoint: .bottomLeading))
                    .frame(width: 150, height: 250)
                    .rotationEffect(.degrees(30))
                    .scaleEffect(x: -1, y: 1) // Espelhar
                    .offset(x: reveal ? 200 : 20, y: reveal ? 100 : 20)
                    .opacity(reveal ? 0 : 1)
            }
            .animation(.easeInOut(duration: 1.2), value: reveal)
        }
        .onAppear { reveal = true }
    }
    
    // Forma simples de folha
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

// MARK: - Cenas Técnicas (Mantidas Perfeitas)
struct TechDemoScene: View {
    var phase: OnboardingView.Phase
    var faceManager: FaceTrackingManager
    
    @State private var demoBrow: Double = 0.0
    @State private var demoPucker: Double = 0.0
    @State private var activeMenuIndex: Int = 0
    @State private var progressValue: Double = 0.0
    @State private var progressColor: Color = .gray
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @State private var timeAccumulator: Double = 0.0
    
    var body: some View {
        HStack(spacing: 40) {
            VStack {
                if phase == .demoBrows {
                    VStack(spacing: 20) {
                        MockRect(label: "Left", color: .juruTeal, isActive: activeMenuIndex == 0)
                        MockRect(label: "Right", color: .juruCoral, isActive: activeMenuIndex == 1)
                    }
                } else {
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 8).frame(width: 120, height: 120)
                        Circle().trim(from: 0, to: progressValue)
                            .stroke(progressColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.05), value: progressValue)
                        Image(systemName: progressColor == .red ? "arrow.uturn.backward" : "checkmark")
                            .font(.largeTitle.bold()).foregroundStyle(progressColor)
                            .opacity(progressValue > 0.1 ? 1 : 0.3)
                            .scaleEffect(progressValue > 0.1 ? 1.1 : 1.0)
                    }
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
        .onAppear { resetLoop() }
        .onChange(of: phase) { resetLoop() }
        .onReceive(timer) { _ in updateLoop() }
    }
    
    struct MockRect: View {
        let label: String; let color: Color; let isActive: Bool
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive ? color : Color.juruCardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(isActive ? .white : color.opacity(0.3), lineWidth: isActive ? 3 : 1))
                    .shadow(color: isActive ? color.opacity(0.5) : .clear, radius: 10)
                Text(label).font(.headline.bold()).foregroundStyle(isActive ? .white : color)
            }
            .frame(height: 60)
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.spring(response: 0.2), value: isActive)
        }
    }
    
    func resetLoop() {
        timeAccumulator = 0.0; demoBrow = 0; demoPucker = 0; activeMenuIndex = 0; progressValue = 0
    }
    
    func updateLoop() {
        timeAccumulator += 0.05
        let t = timeAccumulator
        
        if phase == .demoBrows {
            let cycleTime = t.truncatingRemainder(dividingBy: 3.0)
            if cycleTime < 0.5 { demoBrow = 0.0 }
            else if cycleTime < 1.5 {
                withAnimation(.spring(response: 0.3)) { demoBrow = 1.0 }
                if cycleTime >= 0.6 && cycleTime < 0.65 { withAnimation(.spring) { activeMenuIndex = 1 } }
            } else {
                withAnimation(.spring(response: 0.5)) { demoBrow = 0.0 }
                if cycleTime >= 1.6 && cycleTime < 1.65 { withAnimation(.spring) { activeMenuIndex = 0 } }
            }
        } else if phase == .demoPucker {
            let cycleTime = t.truncatingRemainder(dividingBy: 5.0)
            if cycleTime < 0.5 { demoPucker = 0.0; progressValue = 0.0 }
            else if cycleTime < 3.5 {
                withAnimation(.spring(response: 0.3)) { demoPucker = 1.0 }
                let fillTime = cycleTime - 0.5
                if fillTime < 1.0 { progressColor = .juruTeal; progressValue = fillTime / 0.8 }
                else { progressColor = .red; progressValue = min(1.0, 0.4 + (fillTime - 1.0) * 0.4) }
            } else {
                withAnimation(.spring(response: 0.3)) { demoPucker = 0.0 }; progressValue = 0.0
            }
        }
    }
}

// MARK: - Cena Final
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
