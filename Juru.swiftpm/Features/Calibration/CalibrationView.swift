//
//  CalibrationView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 14/12/25.
//

import SwiftUI

struct CalibrationView: View {
    var faceManager: FaceTrackingManager
    var onCalibrationComplete: () -> Void
    
    enum Step {
        case intro
        case left
        case right
        case pucker
        case done
    }
    
    @State private var currentStep: Step = .intro
    @State private var progress: CGFloat = 0.0
    @State private var demoValue: Double = 0.0
    @State private var isUserTurn: Bool = false
    
    // Feedback Animation States
    @State private var showSuccessOverlay = false
    
    var body: some View {
        ZStack {
            Color.juruBackground.ignoresSafeArea()
            
            // MAIN CONTENT
            VStack(spacing: 0) {
                
                // 1. HEADER (Larger Texts)
                VStack(spacing: 24) {
                    Text(stepTitle)
                        .font(.system(size: 48, weight: .heavy, design: .rounded)) // MUITO MAIOR
                        .foregroundStyle(stepColor)
                        .multilineTextAlignment(.center)
                        .transition(.scale.combined(with: .opacity))
                        .id("Title-\(currentStep)")
                    
                    Text(stepDescription)
                        .font(.system(size: 24, weight: .semibold, design: .rounded)) // MAIOR E MAIS PESADO
                        .foregroundStyle(Color.juruText.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                        .id("Desc-\(currentStep)")
                }
                .padding(.top, 50)
                
                Spacer()
                
                // 2. AVATAR (Centralizado)
                ZStack {
                    Circle()
                        .stroke(Color.juruLead.opacity(0.05), lineWidth: 30)
                        .frame(width: 280, height: 280)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            stepColor,
                            style: StrokeStyle(lineWidth: 30, lineCap: .round)
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: stepColor.opacity(0.3), radius: 10, x: 0, y: 0)
                        .animation(.linear(duration: 0.1), value: progress)
                    
                    JuruAvatarView(
                        faceManager: faceManager,
                        manualSmileLeft: overrideLeft,
                        manualSmileRight: overrideRight,
                        manualPucker: overridePucker,
                        size: 220
                    )
                }
                .scaleEffect(isUserTurn ? 1.05 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isUserTurn)
                
                Spacer()
                
                // 3. ACTION BUTTONS
                VStack {
                    if currentStep == .intro {
                        ActionButton(title: "Start Calibration", color: .juruTeal) {
                            startCalibration()
                        }
                    } else if currentStep == .done {
                        ActionButton(title: "Finish & Start Talking", color: .juruTeal) {
                            onCalibrationComplete()
                        }
                    } else {
                        // Status Indicator
                        HStack(spacing: 12) {
                            Image(systemName: isUserTurn ? "face.smiling.inverse" : "eye.fill")
                                .font(.title3)
                                .symbolEffect(.bounce, value: isUserTurn)
                            
                            Text(isUserTurn ? "YOUR TURN: HOLD" : "WATCH JURU...")
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(isUserTurn ? stepColor : Color.juruSecondaryText)
                                .shadow(color: isUserTurn ? stepColor.opacity(0.5) : Color.black.opacity(0.1), radius: 12, y: 6)
                        )
                    }
                }
                .frame(height: 120)
                .padding(.bottom, 20)
            }
            .opacity(showSuccessOverlay ? 0.0 : 1.0) // Esconde conteúdo durante sucesso
            
            // 4. SUCCESS OVERLAY (O Flash Colorido)
            if showSuccessOverlay {
                ZStack {
                    stepColor.ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 100))
                            .foregroundStyle(.white)
                            .symbolEffect(.bounce)
                        
                        Text("Perfect!")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSuccessOverlay)
        .onChange(of: faceManager.smileLeft) { _, val in handleInput(Float(val), gesture: .smileLeft) }
        .onChange(of: faceManager.smileRight) { _, val in handleInput(Float(val), gesture: .smileRight) }
        .onChange(of: faceManager.mouthPucker) { _, val in handleInput(Float(val), gesture: .pucker) }
    }
    
    // MARK: - Logic (Updated for Overlay)
    
    func completeStep() {
        isUserTurn = false
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Ativa o flash
        withAnimation { showSuccessOverlay = true }
        
        // Aguarda 1.2 segundos mostrando o sucesso antes de mudar
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showSuccessOverlay = false }
            
            switch currentStep {
            case .left: runDemo(for: .right)
            case .right: runDemo(for: .pucker)
            case .pucker: withAnimation { currentStep = .done }
            default: break
            }
        }
    }
    
    // ... (O resto das propriedades e funções helpers permanecem iguais,
    // mas vou repetir aqui para garantir que você tenha o arquivo completo sem erros)
    
    var overrideLeft: Double? {
        if currentStep == .intro || currentStep == .done { return nil }
        if currentStep == .left { return isUserTurn ? nil : demoValue }
        return 0
    }
    var overrideRight: Double? {
        if currentStep == .intro || currentStep == .done { return nil }
        if currentStep == .right { return isUserTurn ? nil : demoValue }
        return 0
    }
    var overridePucker: Double? {
        if currentStep == .intro || currentStep == .done { return nil }
        if currentStep == .pucker { return isUserTurn ? nil : demoValue }
        return 0
    }
    
    var stepColor: Color {
        switch currentStep {
        case .intro: return .juruText
        case .left: return .juruTeal
        case .right: return .juruCoral
        case .pucker: return .juruTeal
        case .done: return .juruTeal
        }
    }
    
    var stepTitle: String {
        switch currentStep {
        case .intro: return "Calibration"
        case .left: return "Left Smile"
        case .right: return "Right Smile"
        case .pucker: return "Pucker"
        case .done: return "All Set!"
        }
    }
    
    var stepDescription: String {
        switch currentStep {
        case .intro: return "I'll learn your facial range in 3 quick steps."
        case .left: return isUserTurn ? "Smile LEFT and HOLD!" : "Watch how to smile left..."
        case .right: return isUserTurn ? "Smile RIGHT and HOLD!" : "Watch the right side..."
        case .pucker: return isUserTurn ? "Make a KISS face and HOLD!" : "Watch the pucker..."
        case .done: return "You are ready to speak with Juru."
        }
    }
    
    func startCalibration() {
        faceManager.setCalibrationMax(for: .smileLeft, value: 0.1)
        faceManager.setCalibrationMax(for: .smileRight, value: 0.1)
        faceManager.setCalibrationMax(for: .pucker, value: 0.1)
        runDemo(for: .left)
    }
    
    func runDemo(for step: Step) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            currentStep = step
            isUserTurn = false
            progress = 0.0
            demoValue = 0.0
        }
        withAnimation(.easeInOut(duration: 1.0).repeatCount(2, autoreverses: true)) {
            demoValue = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            withAnimation(.spring) { isUserTurn = true }
        }
    }
    
    func handleInput(_ value: Float, gesture: FaceGesture) {
        guard isUserTurn else { return }
        
        let isValidInput: Bool
        switch (currentStep, gesture) {
        case (.left, .smileLeft): isValidInput = true
        case (.right, .smileRight): isValidInput = true
        case (.pucker, .pucker): isValidInput = true
        default: isValidInput = false
        }
        
        if isValidInput && value > 0.05 {
            faceManager.setCalibrationMax(for: gesture, value: value)
            withAnimation(.linear(duration: 0.1)) { progress += 0.015 }
            if progress >= 1.0 { completeStep() }
        }
    }
}

// Action Button Component
struct ActionButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2.bold()) // Fonte aumentada
                .foregroundStyle(.white)
                .padding(.vertical, 20) // Botão mais gordinho
                .frame(maxWidth: .infinity)
                .background(color)
                .clipShape(Capsule())
                .shadow(color: color.opacity(0.4), radius: 12, y: 6)
        }
        .padding(.horizontal, 40)
    }
}
