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
    
    enum Step { case neutral, brows, pucker, done }
    
    @State private var currentStep: Step = .neutral
    @State private var progress: CGFloat = 0.0
    @State private var isUserTurn: Bool = false
    
    // --- ESTADO DE PREPARAÇÃO (Countdown) ---
    @State private var isPreparing: Bool = true
    @State private var startCountdown: Double = 3.9 // Começa quase em 4 para mostrar o 3 cheio
    
    // Feedback Visual de Sucesso
    @State private var showSuccessFeedback: Bool = false
    
    // Animação da Demo (Loop)
    @State private var animBrow: Double = 0.0
    @State private var animPucker: Double = 0.0
    
    // Coleta de Dados
    @State private var neutralCount: Int = 0
    @State private var neutralBrowSum: Double = 0
    @State private var neutralPuckerSum: Double = 0
    
    // Timer para Animação Demo e Coleta Neutral
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @State private var timeAccumulator: Double = 0.0
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let isPad = geo.size.width > 600
            // Escala dinâmica para iPad
            let scale = isPad ? (isLandscape ? 1.2 : 1.3) : 1.0
            
            ZStack {
                Color.juruBackground.ignoresSafeArea()
                
                // Background Decorativo Sutil
                AmbientCalibrationBackground(step: currentStep, scale: scale)
                
                if isLandscape {
                    // --- LAYOUT HORIZONTAL (iPad Landscape) ---
                    HStack(spacing: 40) {
                        // ESQUERDA: Textos e Controles
                        VStack(alignment: .leading, spacing: 40) {
                            Spacer()
                            InstructionText(step: currentStep, scale: scale, align: .leading)
                            
                            ControlsView(
                                currentStep: currentStep,
                                isUserTurn: isUserTurn,
                                stepColor: stepColor,
                                scale: scale,
                                onAction: onCalibrationComplete
                            )
                            Spacer()
                        }
                        .frame(width: geo.size.width * 0.4) // 40% da largura
                        .padding(.leading, 60)
                        
                        // DIREITA: Avatar Centralizado
                        ZStack {
                            AvatarHeroArea(
                                faceManager: faceManager,
                                progress: progress,
                                animBrow: isUserTurn ? nil : animBrow,
                                animPucker: isUserTurn ? nil : animPucker,
                                showSuccessFeedback: showSuccessFeedback,
                                stepColor: stepColor,
                                scale: scale * 1.1 // Avatar um pouco maior no iPad
                            )
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    // --- LAYOUT VERTICAL (iPhone / iPad Portrait) ---
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Avatar no Centro/Topo (Hero)
                        AvatarHeroArea(
                            faceManager: faceManager,
                            progress: progress,
                            animBrow: isUserTurn ? nil : animBrow,
                            animPucker: isUserTurn ? nil : animPucker,
                            showSuccessFeedback: showSuccessFeedback,
                            stepColor: stepColor,
                            scale: scale
                        )
                        .padding(.top, 40)
                        
                        Spacer()
                        
                        // Texto e Controles na parte inferior (Mais acessível)
                        VStack(spacing: 30 * scale) {
                            InstructionText(step: currentStep, scale: scale, align: .center)
                                .padding(.horizontal, 30)
                            
                            ControlsView(
                                currentStep: currentStep,
                                isUserTurn: isUserTurn,
                                stepColor: stepColor,
                                scale: scale,
                                onAction: onCalibrationComplete
                            )
                        }
                        .padding(.bottom, 50)
                        .background(
                            // Gradiente suave atrás do texto para leitura
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .mask(LinearGradient(colors: [.clear, .black, .black], startPoint: .top, endPoint: .bottom))
                                .ignoresSafeArea()
                                .padding(.top, -100)
                        )
                    }
                }
                
                // --- OVERLAY DE CONTAGEM REGRESSIVA ---
                if isPreparing {
                    Color.black.opacity(0.7).ignoresSafeArea()
                        .transition(.opacity)
                    
                    VStack(spacing: 20 * scale) {
                        Text("Get Ready")
                            .font(.juruFont(.title, weight: .bold))
                            .foregroundStyle(.white)
                            .opacity(0.9)
                        
                        Text("\(Int(startCountdown))")
                            .font(.system(size: 100 * scale, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.juruTeal)
                            .contentTransition(.numericText())
                            .shadow(color: .juruTeal.opacity(0.5), radius: 20)
                            .id(Int(startCountdown)) // Força animação na troca de número
                    }
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
                }
            }
        }
        // Sensores
        .onChange(of: faceManager.rawValues[.browUp]) { _, val in handleInput(Float(val ?? 0), gesture: .browUp) }
        .onChange(of: faceManager.rawValues[.pucker]) { _, val in handleInput(Float(val ?? 0), gesture: .pucker) }
        // Loop de Animação e Coleta
        .onReceive(timer) { _ in
            if isPreparing {
                // Lógica de Contagem Regressiva
                if startCountdown > 1.0 {
                    withAnimation(.linear(duration: 0.05)) {
                        startCountdown -= 0.05
                    }
                } else {
                    // Fim da contagem
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPreparing = false
                    }
                }
            } else {
                // Lógica Normal de Calibração (Só roda após a contagem)
                if currentStep == .neutral {
                    collectNeutralData()
                } else if !isUserTurn && (currentStep == .brows || currentStep == .pucker) {
                    updateDemoLoop()
                }
            }
        }
    }
    
    // MARK: - Componentes Visuais
    
    struct InstructionText: View {
        let step: CalibrationView.Step
        let scale: CGFloat
        let align: TextAlignment
        
        var body: some View {
            VStack(alignment: align == .leading ? .leading : .center, spacing: 16 * scale) {
                Text(title)
                    .font(.juruFont(.largeTitle, weight: .heavy))
                    .scaleEffect(scale)
                    .foregroundStyle(color)
                    .transition(.blurReplace)
                    .id("T-\(step)")
                
                // Texto Secundário
                Text(description)
                    .font(.system(size: 26 * scale, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.juruText.opacity(0.95))
                    .multilineTextAlignment(align)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
                    .id("D-\(step)")
            }
        }
        
        var title: String {
            switch step {
            case .neutral: return "Relax Face"
            case .brows: return "Navigation"
            case .pucker: return "Selection"
            case .done: return "All Set!"
            }
        }
        
        var description: String {
            switch step {
            case .neutral: return "Keep your face natural and still.\nFinding your zero point..."
            case .brows: return "Raise your eyebrows high to verify range."
            case .pucker: return "Make a kiss face to test selection."
            case .done: return "Calibration complete.\nYour voice is ready."
            }
        }
        
        var color: Color {
            switch step {
            case .neutral: return .gray
            case .brows: return .juruTeal
            case .pucker: return .juruCoral
            case .done: return .juruGold
            }
        }
    }
    
    struct AvatarHeroArea: View {
        var faceManager: FaceTrackingManager
        let progress: CGFloat
        let animBrow: Double?
        let animPucker: Double?
        let showSuccessFeedback: Bool
        let stepColor: Color
        let scale: CGFloat
        
        var body: some View {
            let size = 260 * scale
            ZStack {
                // Anel Fundo
                Circle()
                    .stroke(Color.juruText.opacity(0.1), lineWidth: 24 * scale)
                    .frame(width: size + 50, height: size + 50)
                
                // Anel Progresso
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(stepColor, style: StrokeStyle(lineWidth: 24 * scale, lineCap: .round))
                    .frame(width: size + 50, height: size + 50)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: stepColor.opacity(0.6), radius: 20)
                    .animation(.linear(duration: 0.1), value: progress)
                
                // Avatar
                JuruAvatarView(
                    faceManager: faceManager,
                    manualBrowUp: animBrow,
                    manualPucker: animPucker,
                    size: size
                )
                .opacity(showSuccessFeedback ? 0.3 : 1.0)
                .blur(radius: showSuccessFeedback ? 15 : 0)
                
                // Feedback de Sucesso
                if showSuccessFeedback {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 120 * scale))
                        .foregroundStyle(.white)
                        .shadow(color: stepColor, radius: 30)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
    
    struct ControlsView: View {
        let currentStep: CalibrationView.Step
        let isUserTurn: Bool
        let stepColor: Color
        let scale: CGFloat
        let onAction: () -> Void
        
        var body: some View {
            VStack {
                if currentStep == .done {
                    Button(action: onAction) {
                        Text("Go to Juru Main")
                            .font(.system(size: 24 * scale, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 22 * scale)
                            .frame(maxWidth: 400 * scale)
                            .background(Color.juruTeal)
                            .clipShape(Capsule())
                            .shadow(color: Color.juruTeal.opacity(0.4), radius: 15, y: 5)
                    }
                } else if currentStep == .neutral {
                    HStack(spacing: 16) {
                        ProgressView().tint(.juruText).scaleEffect(1.5)
                        Text("Calibrating...")
                            .font(.system(size: 22 * scale, weight: .semibold))
                            .foregroundStyle(Color.juruSecondaryText)
                    }
                    .padding(24 * scale)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                } else {
                    HStack(spacing: 16 * scale) {
                        Image(systemName: isUserTurn ? "record.circle.fill" : "eye.fill")
                            .symbolEffect(.bounce, value: isUserTurn)
                            .font(.system(size: 28 * scale))
                        
                        Text(isUserTurn ? "YOUR TURN" : "WATCH JURU")
                            .font(.system(size: 24 * scale, weight: .bold))
                    }
                    .foregroundStyle(isUserTurn ? .white : Color.juruText)
                    .padding(.horizontal, 40 * scale)
                    .padding(.vertical, 20 * scale)
                    .background(
                        Capsule().fill(isUserTurn ? stepColor : Color.juruCardBackground)
                            .shadow(color: isUserTurn ? stepColor.opacity(0.4) : Color.black.opacity(0.05), radius: 15)
                    )
                    .animation(.spring, value: isUserTurn)
                }
            }
        }
    }
    
    struct AmbientCalibrationBackground: View {
        let step: CalibrationView.Step
        let scale: CGFloat
        var color: Color {
            switch step {
            case .neutral: return .gray
            case .brows: return .juruTeal
            case .pucker: return .juruCoral
            case .done: return .juruGold
            }
        }
        var body: some View {
            GeometryReader { proxy in
                Circle().fill(color.opacity(0.12))
                    .frame(width: 800 * scale).blur(radius: 200)
                    .position(x: proxy.size.width/2, y: proxy.size.height*0.5)
                    .animation(.easeInOut(duration: 1.5), value: step)
            }
        }
    }
    
    // MARK: - Logic & Animation Loop
    
    var stepColor: Color {
        switch currentStep {
        case .neutral: return .gray
        case .brows: return .juruTeal
        case .pucker: return .juruCoral
        case .done: return .juruGold
        }
    }
    
    // Atualiza a animação do Avatar (Demo)
    func updateDemoLoop() {
        timeAccumulator += 0.05
        
        if currentStep == .brows {
            // Ciclo: 2.5 segundos
            let cycle = timeAccumulator.truncatingRemainder(dividingBy: 2.5)
            
            if cycle < 0.5 { // Prepara
                withAnimation(.spring(response: 0.4)) { animBrow = 0.0 }
            } else if cycle < 1.5 { // Ação: Levanta Sobrancelha (Hold)
                withAnimation(.spring(response: 0.3)) { animBrow = 1.0 }
            } else { // Relaxa
                withAnimation(.spring(response: 0.4)) { animBrow = 0.0 }
            }
            
        } else if currentStep == .pucker {
            // Ciclo: 2.5 segundos
            let cycle = timeAccumulator.truncatingRemainder(dividingBy: 2.5)
            
            if cycle < 0.5 { // Prepara
                withAnimation(.spring(response: 0.4)) { animPucker = 0.0 }
            } else if cycle < 1.5 { // Ação: Bico (Hold)
                withAnimation(.spring(response: 0.3)) { animPucker = 1.0 }
            } else { // Relaxa
                withAnimation(.spring(response: 0.4)) { animPucker = 0.0 }
            }
        }
    }
    
    func collectNeutralData() {
        if neutralCount < 20 { // 1.0 segundo de calibração
            neutralBrowSum += faceManager.rawValues[.browUp] ?? 0
            neutralPuckerSum += faceManager.rawValues[.pucker] ?? 0
            neutralCount += 1
            withAnimation { progress = CGFloat(neutralCount) / 20.0 }
        } else {
            let avgBrow = Float(neutralBrowSum / Double(neutralCount))
            let avgPucker = Float(neutralPuckerSum / Double(neutralCount))
            faceManager.setRestingBase(for: .browUp, value: avgBrow)
            faceManager.setRestingBase(for: .pucker, value: avgPucker)
            triggerSuccessAndNext(to: .brows)
        }
    }
    
    func triggerSuccessAndNext(to nextStep: Step) {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showSuccessFeedback = true }
        
        // Pausa de 1.2s para mostrar o sucesso
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showSuccessFeedback = false
                currentStep = nextStep
                if nextStep != .done { isUserTurn = false }
                progress = 0.0
                timeAccumulator = 0.0 // Reset loop de animação
                animBrow = 0.0
                animPucker = 0.0
            }
            // Delay para dar a vez ao usuário após ver a demo
            if nextStep != .done {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { // Demo roda por 3s
                    withAnimation { isUserTurn = true }
                }
            }
        }
    }
    
    func handleInput(_ val: Float, gesture: FaceGesture) {
        guard isUserTurn else { return }
        
        let base = faceManager.calibration.restingBase[gesture] ?? 0.0
        let corrected = Double(val) - base
        let correct = (currentStep == .brows && gesture == .browUp) || (currentStep == .pucker && gesture == .pucker)
        
        if correct && corrected > 0.1 {
            faceManager.setCalibrationMax(for: gesture, value: val)
            // Preenche o progresso conforme o usuário sustenta a expressão
            withAnimation(.linear(duration: 0.1)) { progress += 0.02 }
            if progress >= 1.0 { completeStep() }
        }
    }
    
    func completeStep() {
        isUserTurn = false
        if currentStep == .brows { triggerSuccessAndNext(to: .pucker) }
        else if currentStep == .pucker { triggerSuccessAndNext(to: .done) }
    }
}
