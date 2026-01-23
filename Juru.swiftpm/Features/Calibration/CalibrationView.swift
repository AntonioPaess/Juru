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
        case neutral
        case brows
        case pucker
        case done
    }
    
    @State private var currentStep: Step = .neutral
    @State private var progress: CGFloat = 0.0
    @State private var demoValue: Double = 0.0
    @State private var isUserTurn: Bool = false
    
    @State private var neutralCollectionCount: Int = 0
    @State private var neutralBrowSum: Double = 0
    @State private var neutralPuckerSum: Double = 0
    let neutralTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var stepColor: Color {
        switch currentStep {
        case .neutral: return .gray
        case .brows: return .juruTeal
        case .pucker: return .juruCoral
        case .done: return .juruGold
        }
    }
    
    var body: some View {
        ZStack {
            Color.juruBackground.ignoresSafeArea()
            decorationBackground
            
            VStack(spacing: 0) {
                headerView
                Spacer()
                avatarDisplayView
                Spacer()
                controlsView
            }
        }
        .onChange(of: faceManager.rawValues[.browUp]) { _, val in handleInput(Float(val ?? 0), gesture: .browUp) }
        .onChange(of: faceManager.rawValues[.pucker]) { _, val in handleInput(Float(val ?? 0), gesture: .pucker) }
        .onReceive(neutralTimer) { _ in
            if currentStep == .neutral { collectNeutralData() }
        }
    }
    
    private var decorationBackground: some View {
        GeometryReader { proxy in
            Circle()
                .fill(stepColor.opacity(0.15))
                .frame(width: 500, height: 500)
                .blur(radius: 100)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .animation(.easeInOut(duration: 1.0), value: currentStep)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 20) {
            Text(stepTitle)
                .font(.juruFont(.largeTitle, weight: .heavy))
                .foregroundStyle(stepColor)
                .multilineTextAlignment(.center)
                .transition(.opacity)
                .id("Title-\(currentStep)")
            
            Text(stepDescription)
                .font(.juruFont(.title3, weight: .medium))
                .foregroundStyle(Color.juruText.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .fixedSize(horizontal: false, vertical: true)
                .transition(.opacity)
                .id("Desc-\(currentStep)")
        }
        .padding(.top, 60)
        .frame(height: 200, alignment: .top)
    }
    
    private var avatarDisplayView: some View {
        ZStack {
            Circle().stroke(Color.juruText.opacity(0.1), lineWidth: 20).frame(width: 280, height: 280)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(stepColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
            
            JuruAvatarView(
                faceManager: faceManager,
                manualBrowUp: overrideBrows,
                manualPucker: overridePucker,
                size: 230
            )
        }
        .scaleEffect(currentStep == .done ? 1.1 : 1.0)
    }
    
    private var controlsView: some View {
        VStack {
            if currentStep == .done {
                ActionButton(title: "Go to Juru Main", color: .juruTeal) {
                    onCalibrationComplete()
                }
            } else if currentStep == .neutral {
                VStack(spacing: 8) {
                    ProgressView().tint(.juruText)
                    Text("Relaxing Face Sensors...")
                        .font(.juruFont(.headline))
                        .foregroundStyle(Color.juruSecondaryText)
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: isUserTurn ? "record.circle.fill" : "eye.fill")
                        .symbolEffect(.bounce, value: isUserTurn)
                    Text(isUserTurn ? "YOUR TURN: HOLD" : "OBSERVE JURU...")
                }
                .font(.juruFont(.headline, weight: .bold))
                .foregroundStyle(isUserTurn ? .white : Color.juruText)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    Capsule().fill(isUserTurn ? stepColor : Color.juruCardBackground)
                        .shadow(color: isUserTurn ? stepColor.opacity(0.4) : Color.black.opacity(0.1), radius: 10, y: 5)
                )
                .transition(.scale)
            }
        }
        .frame(height: 100)
        .padding(.bottom, 50)
    }
    
    var overrideBrows: Double? {
        if currentStep == .brows { return isUserTurn ? nil : demoValue }
        return 0
    }
    var overridePucker: Double? {
        if currentStep == .pucker { return isUserTurn ? nil : demoValue }
        return 0
    }
    
    var stepTitle: String {
        switch currentStep {
        case .neutral: return "Relax Face"
        case .brows: return "Raise Brows"
        case .pucker: return "Pucker Up"
        case .done: return "Perfect!"
        }
    }
    
    var stepDescription: String {
        switch currentStep {
        case .neutral: return "Keep your face completely still and relaxed.\nFinding your zero point..."
        case .brows: return isUserTurn ? "Now you! Raise eyebrows and HOLD." : "Watch Juru..."
        case .pucker: return isUserTurn ? "Make a kiss face and HOLD." : "Watch Juru..."
        case .done: return "Calibration saved.\nYou are ready to speak."
        }
    }
    
    func collectNeutralData() {
        if neutralCollectionCount < 15 {
            neutralBrowSum += faceManager.rawValues[.browUp] ?? 0
            neutralPuckerSum += faceManager.rawValues[.pucker] ?? 0
            neutralCollectionCount += 1
            withAnimation { progress = CGFloat(neutralCollectionCount) / 15.0 }
        } else {
            let avgBrow = Float(neutralBrowSum / Double(neutralCollectionCount))
            let avgPucker = Float(neutralPuckerSum / Double(neutralCollectionCount))
            
            faceManager.setRestingBase(for: .browUp, value: avgBrow)
            faceManager.setRestingBase(for: .pucker, value: avgPucker)
            
            runDemo(for: .brows)
        }
    }
    
    func runDemo(for step: Step) {
        withAnimation(.spring) {
            currentStep = step
            isUserTurn = false
            progress = 0.0
            demoValue = 0.0
        }
        withAnimation(.easeInOut(duration: 1.0).repeatCount(2, autoreverses: true)) { demoValue = 1.0 }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            withAnimation(.spring) { isUserTurn = true }
        }
    }
    
    func handleInput(_ rawValue: Float, gesture: FaceGesture) {
        guard isUserTurn else { return }
        
        let isCorrectGesture: Bool
        switch (currentStep, gesture) {
        case (.brows, .browUp): isCorrectGesture = true
        case (.pucker, .pucker): isCorrectGesture = true
        default: isCorrectGesture = false
        }
        
        let base = faceManager.calibration.restingBase[gesture] ?? 0.0
        let correctedValue = Double(rawValue) - base
        
        if isCorrectGesture && correctedValue > 0.1 {
            faceManager.setCalibrationMax(for: gesture, value: rawValue)
            withAnimation(.linear(duration: 0.1)) { progress += 0.02 }
            if progress >= 1.0 { completeStep() }
        }
    }
    
    func completeStep() {
        isUserTurn = false
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
        
        switch currentStep {
        case .brows: runDemo(for: .pucker)
        case .pucker: withAnimation { currentStep = .done }
        default: break
        }
    }
}

// Struct restaurada para corrigir o erro
struct ActionButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(color)
                .clipShape(Capsule())
                .shadow(color: color.opacity(0.3), radius: 10, y: 5)
        }
        .padding(.horizontal, 40)
    }
}
