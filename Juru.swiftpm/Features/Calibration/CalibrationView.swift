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
    
    var body: some View {
        ZStack {
            Color.juruBackground.ignoresSafeArea()
            
            // Decorative background glow using palette
            GeometryReader { proxy in
                Circle()
                    .fill(stepColor.opacity(0.1))
                    .frame(width: 500, height: 500)
                    .blur(radius: 100)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    .animation(.easeInOut(duration: 1.0), value: currentStep)
            }
            
            VStack(spacing: 0) {
                // 1. DYNAMIC TEXT AREA (English)
                VStack(spacing: 20) {
                    Text(stepTitle)
                        .font(.system(size: 48, weight: .heavy, design: .rounded)) // Hero Font
                        .foregroundStyle(stepColor)
                        .multilineTextAlignment(.center)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity).combined(with: .scale)
                        ))
                        .id("Title-\(currentStep)")
                    
                    Text(stepDescription)
                        .font(.system(size: 22, weight: .medium, design: .rounded)) // Legible Instruction
                        .foregroundStyle(Color.juruText.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                        .transition(.opacity)
                        .id("Desc-\(currentStep)")
                }
                .padding(.top, 60)
                .frame(height: 200, alignment: .top)
                
                Spacer()
                
                // 2. AVATAR AREA
                ZStack {
                    // Base Ring
                    Circle()
                        .stroke(Color.juruLead.opacity(0.05), lineWidth: 20)
                        .frame(width: 280, height: 280)
                    
                    // Progress Ring
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            stepColor,
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: stepColor.opacity(0.3), radius: 10, x: 0, y: 0)
                        .animation(.linear(duration: 0.1), value: progress)
                    
                    // Interactive Avatar (Mirrors or Demos)
                    JuruAvatarView(
                        faceManager: faceManager,
                        manualSmileLeft: overrideLeft,
                        manualSmileRight: overrideRight,
                        manualPucker: overridePucker,
                        size: 230
                    )
                }
                .scaleEffect(currentStep == .done ? 1.1 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: currentStep)
                
                Spacer()
                
                // 3. ACTION/STATUS AREA
                VStack {
                    if currentStep == .intro {
                        ActionButton(title: "Start Calibration", color: .juruTeal) {
                            startCalibration()
                        }
                    } else if currentStep == .done {
                        ActionButton(title: "Go to Juru Main", color: .juruTeal) {
                            onCalibrationComplete()
                        }
                    } else {
                        // Status Pill with Palette
                        HStack(spacing: 12) {
                            Image(systemName: isUserTurn ? "record.circle.fill" : "eye.fill")
                                .symbolEffect(.bounce, value: isUserTurn)
                            Text(isUserTurn ? "YOUR TURN: HOLD" : "OBSERVE JURU...")
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white) // Max contrast text
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(isUserTurn ? stepColor : Color.juruSecondaryText)
                                .shadow(color: isUserTurn ? stepColor.opacity(0.4) : Color.black.opacity(0.1), radius: 10, y: 5)
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 100)
                .padding(.bottom, 50)
            }
        }
        // Observing computational values from FaceTrackingManager
        .onChange(of: faceManager.smileLeft) { _, val in handleInput(Float(val), gesture: .smileLeft) }
        .onChange(of: faceManager.smileRight) { _, val in handleInput(Float(val), gesture: .smileRight) }
        .onChange(of: faceManager.mouthPucker) { _, val in handleInput(Float(val), gesture: .pucker) }
    }
    
    // MARK: - Avatar Demo Logic
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
    
    // MARK: - English Text & Strictly Branding Colors
    
    var stepColor: Color {
        switch currentStep {
        case .intro: return .juruText // Default
        case .left: return .juruTeal // Teal for Left
        case .right: return .juruCoral // Coral for Right
        case .pucker: return .juruTeal // Repeating Teal for balance
        case .done: return .juruTeal
        }
    }
    
    var stepTitle: String {
        switch currentStep {
        case .intro: return "Calibration"
        case .left: return "Smile Left"
        case .right: return "Smile Right"
        case .pucker: return "Pucker Up"
        case .done: return "All Set!"
        }
    }
    
    var stepDescription: String {
        switch currentStep {
        case .intro: return "Juru needs to learn your unique micro-expressions to work perfectly."
        case .left: return isUserTurn ? "Now you!\nSmile gently left and HOLD." : "Watch Juru guide you..."
        case .right: return isUserTurn ? "Your turn!\nSmile gently right and HOLD." : "Observe the other side..."
        case .pucker: return isUserTurn ? "Now make a kiss face\nand HOLD firmly." : "Watch Juru make the pucker..."
        case .done: return "Your expressions have been saved.\nYou are ready to speak."
        }
    }
    
    // MARK: - Logic
    func startCalibration() {
        // Reset calibration factors
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
        
        // Demo cycle animation for the avatar
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
            
            withAnimation(.linear(duration: 0.1)) {
                progress += 0.015 // Fill speed
            }
            
            if progress >= 1.0 {
                completeStep()
            }
        }
    }
    
    func completeStep() {
        isUserTurn = false
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        switch currentStep {
        case .left: runDemo(for: .right)
        case .right: runDemo(for: .pucker)
        case .pucker: withAnimation { currentStep = .done }
        default: break
        }
    }
}

// Componente de Botão com Máximo Contraste (White text on Brand color)
struct ActionButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.white) // EXPLICIT WHITE TEXT FOR READABILITY
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(color) // JuruTeal or JuruCoral
                .cornerRadius(24)
                .shadow(color: color.opacity(0.3), radius: 10, y: 5)
        }
        .padding(.horizontal, 40)
    }
}
