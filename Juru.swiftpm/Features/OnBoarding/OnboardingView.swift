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
        case origin = 0
        case purpose
        case demoBrows
        case demoPucker
        case ready
    }
    
    @State private var currentPhase: Phase = .origin
    
    var body: some View {
        ZStack {
            AmbientBackground().ignoresSafeArea()
            
            VStack(spacing: 0) {
                ZStack {
                    if currentPhase == .origin || currentPhase == .purpose {
                        ConceptScene(phase: currentPhase)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
                    
                    HStack(spacing: 8) {
                        ForEach(Phase.allCases, id: \.self) { p in
                            Capsule()
                                .fill(p == currentPhase ? Color.juruTeal : Color.gray.opacity(0.3))
                                .frame(width: p == currentPhase ? 32 : 8, height: 8)
                                .animation(.spring, value: currentPhase)
                        }
                    }
                    
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
        case .origin: return "The Sacred Portal"
        case .purpose: return "When Silence Falls"
        case .demoBrows: return "You Lead"
        case .demoPucker: return "You Choose"
        case .ready: return "Juru is Yours"
        }
    }
    
    var subtitleText: String {
        switch currentPhase {
        case .origin:
            return "In Tupi-Guarani, 'Juru' means Mouth.\nIt is the gateway to our soul and identity."
        case .purpose:
            return "For those with ALS or paralysis, the body may freeze, but the face remains alive. We turn micro-gestures into freedom."
        case .demoBrows:
            return "Raise your eyebrows to switch focus.\nSee how the menu reacts instantly?"
        case .demoPucker:
            return "Hold a Pucker (Kiss) to interact.\nGreen to Select. Long hold (Red) to Delete."
        case .ready:
            return "I need to learn your unique expressions.\nRelax your face, and let's begin."
        }
    }
}

struct ConceptScene: View {
    var phase: OnboardingView.Phase
    @State private var animate = false
    
    var body: some View {
        ZStack {
            if phase == .origin {
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.juruTeal.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 200
                                )
                            )
                            .frame(width: 200 + CGFloat(i*100), height: 200 + CGFloat(i*100))
                            .scaleEffect(animate ? 1.2 : 0.8)
                            .opacity(animate ? 0.0 : 0.5)
                            .animation(
                                .easeOut(duration: 4.0)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 1.3),
                                value: animate
                            )
                    }
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.juruTeal, .juruBackground],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .shadow(color: .juruTeal.opacity(0.6), radius: 30, x: 0, y: 0)
                        .overlay(
                            Image("Juru-White")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80)
                                .opacity(0.9)
                        )
                        .scaleEffect(animate ? 1.05 : 0.95)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animate)
                }
                .transition(.opacity)
                
            } else {
                ZStack {
                    Circle()
                        .fill(Color.juruCoral.opacity(0.1))
                        .frame(width: 300, height: 300)
                        .blur(radius: 50)
                    
                    VStack(spacing: 20) {
                        HStack(spacing: 6) {
                            ForEach(0..<10) { i in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.juruCoral, .juruGold],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(width: 8, height: animate ? CGFloat.random(in: 40...120) : 10)
                                    .animation(
                                        .spring(response: 0.4, dampingFraction: 0.5)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.1),
                                        value: animate
                                    )
                            }
                        }
                    }
                    .shadow(color: .juruCoral.opacity(0.5), radius: 20)
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

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
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: progressValue)
                            .stroke(progressColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.05), value: progressValue)
                        
                        Image(systemName: progressColor == .red ? "arrow.uturn.backward" : "checkmark")
                            .font(.largeTitle.bold())
                            .foregroundStyle(progressColor)
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
        let label: String
        let color: Color
        let isActive: Bool
        
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive ? color : Color.juruCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isActive ? .white : color.opacity(0.3), lineWidth: isActive ? 3 : 1)
                    )
                    .shadow(color: isActive ? color.opacity(0.5) : .clear, radius: 10)
                
                Text(label)
                    .font(.headline.bold())
                    .foregroundStyle(isActive ? .white : color)
            }
            .frame(height: 60)
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.spring(response: 0.2), value: isActive)
        }
    }
    
    func resetLoop() {
        timeAccumulator = 0.0
        demoBrow = 0
        demoPucker = 0
        activeMenuIndex = 0
        progressValue = 0
    }
    
    func updateLoop() {
        timeAccumulator += 0.05
        let t = timeAccumulator
        
        if phase == .demoBrows {
            let cycleTime = t.truncatingRemainder(dividingBy: 3.0)
            
            if cycleTime < 0.5 {
                demoBrow = 0.0
            } else if cycleTime < 1.5 {
                withAnimation(.spring(response: 0.3)) { demoBrow = 1.0 }
                if cycleTime >= 0.6 && cycleTime < 0.65 {
                    withAnimation(.spring) { activeMenuIndex = 1 }
                }
            } else {
                withAnimation(.spring(response: 0.5)) { demoBrow = 0.0 }
                if cycleTime >= 1.6 && cycleTime < 1.65 {
                    withAnimation(.spring) { activeMenuIndex = 0 }
                }
            }
            
        } else if phase == .demoPucker {
            let cycleTime = t.truncatingRemainder(dividingBy: 5.0)
            
            if cycleTime < 0.5 {
                demoPucker = 0.0
                progressValue = 0.0
            } else if cycleTime < 3.5 {
                withAnimation(.spring(response: 0.3)) { demoPucker = 1.0 }
                let fillTime = cycleTime - 0.5
                if fillTime < 1.0 {
                    progressColor = .juruTeal
                    progressValue = fillTime / 0.8
                } else {
                    progressColor = .red
                    progressValue = min(1.0, 0.4 + (fillTime - 1.0) * 0.4)
                }
            } else {
                withAnimation(.spring(response: 0.3)) { demoPucker = 0.0 }
                progressValue = 0.0
            }
        }
    }
}

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
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                dance = true
            }
        }
    }
}
