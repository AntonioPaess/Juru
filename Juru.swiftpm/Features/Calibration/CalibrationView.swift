//
//  CalibrationView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 14/12/25.
//

import SwiftUI

/// A view that guides users through the facial gesture calibration process.
///
/// The calibration flow consists of four steps:
/// 1. **Neutral**: Captures the user's resting facial state (baseline) over 1 second
/// 2. **Brows**: User raises eyebrows to set the navigation gesture threshold
/// 3. **Pucker**: User makes a kiss face to set the selection gesture threshold
/// 4. **Done**: Calibration complete, user can proceed to main app
///
/// ## Architecture
/// Uses `TimelineView` with controlled tick intervals to prevent memory leaks
/// that would occur with traditional `Timer.publish`. The tick rate is controlled
/// by `tickInterval` (50ms) with guard clauses ensuring consistent timing regardless
/// of view re-renders.
///
/// ## Animation Loop
/// During the brows and pucker steps, an animated demo shows the user what gesture
/// to perform before it becomes their turn to replicate it.
struct CalibrationView: View {
    var faceManager: FaceTrackingManager
    var onCalibrationComplete: () -> Void

    /// Represents the current step in the calibration flow
    enum Step { case neutral, brows, pucker, done }

    @State private var currentStep: Step = .neutral
    @State private var progress: CGFloat = 0.0
    @State private var isUserTurn: Bool = false
    @State private var isPreparing: Bool = true
    @State private var startCountdown: Double = 3.9
    @State private var showSuccessFeedback: Bool = false
    @State private var animBrow: Double = 0.0
    @State private var animPucker: Double = 0.0
    @State private var neutralCount: Int = 0
    @State private var neutralBrowSum: Double = 0
    @State private var neutralPuckerSum: Double = 0
    @State private var lastTickTime: Date = .distantPast
    @State private var lastNeutralCollectTime: Date = .distantPast

    /// The minimum interval between timeline ticks (50ms = 20Hz)
    private let tickInterval: TimeInterval = 0.05

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.05)) { timeline in
            GeometryReader { geo in
                let isLandscape = geo.size.width > geo.size.height
                let isPad = geo.size.width > 600
                let scale = isPad ? (isLandscape ? 1.2 : 1.3) : 1.0

                ZStack {
                    Color.juruBackground.ignoresSafeArea()
                    AmbientCalibrationBackground(step: currentStep, scale: scale)

                    if isLandscape {
                        HStack(spacing: 40) {
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
                            .frame(width: geo.size.width * 0.4)
                            .padding(.leading, 60)

                            ZStack {
                                AvatarHeroArea(
                                    faceManager: faceManager,
                                    progress: progress,
                                    animBrow: isUserTurn ? nil : animBrow,
                                    animPucker: isUserTurn ? nil : animPucker,
                                    showSuccessFeedback: showSuccessFeedback,
                                    stepColor: stepColor,
                                    scale: scale * 1.1
                                )
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        VStack(spacing: 0) {
                            Spacer()
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
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .mask(LinearGradient(colors: [.clear, .black, .black], startPoint: .top, endPoint: .bottom))
                                    .ignoresSafeArea()
                                    .padding(.top, -100)
                            )
                        }
                    }

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
                                .id(Int(startCountdown))
                        }
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(100)
                    }
                }
            }
            .onChange(of: timeline.date) { _, _ in
                handleTimelineTick()
            }
        }
        .onChange(of: faceManager.rawValues[.browUp]) { _, val in handleInput(Float(val ?? 0), gesture: .browUp) }
        .onChange(of: faceManager.rawValues[.pucker]) { _, val in handleInput(Float(val ?? 0), gesture: .pucker) }
    }

    /// Processes each timeline tick with controlled frequency.
    ///
    /// This method ensures consistent 50ms intervals between updates regardless of
    /// how frequently the TimelineView triggers due to other state changes.
    /// Uses guard clause to skip processing if insufficient time has elapsed.
    private func handleTimelineTick() {
        let now = Date.now
        let elapsed = now.timeIntervalSince(lastTickTime)

        guard elapsed >= tickInterval else { return }
        lastTickTime = now

        if isPreparing {
            if startCountdown > 1.0 {
                withAnimation(.linear(duration: 0.05)) {
                    startCountdown -= tickInterval
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    isPreparing = false
                }
            }
        } else {
            if currentStep == .neutral {
                collectNeutralData(now: now)
            } else if !isUserTurn && (currentStep == .brows || currentStep == .pucker) {
                updateDemoLoop(elapsed: tickInterval)
            }
        }
    }

    // MARK: - Components

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
                Circle()
                    .stroke(Color.juruText.opacity(0.1), lineWidth: 24 * scale)
                    .frame(width: size + 50, height: size + 50)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(stepColor, style: StrokeStyle(lineWidth: 24 * scale, lineCap: .round))
                    .frame(width: size + 50, height: size + 50)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: stepColor.opacity(0.6), radius: 20)
                    .animation(.linear(duration: 0.1), value: progress)

                JuruAvatarView(
                    faceManager: faceManager,
                    manualBrowUp: animBrow,
                    manualPucker: animPucker,
                    size: size
                )
                .opacity(showSuccessFeedback ? 0.3 : 1.0)
                .blur(radius: showSuccessFeedback ? 15 : 0)

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

    // MARK: - Logic

    /// Returns the theme color for the current calibration step
    var stepColor: Color {
        switch currentStep {
        case .neutral: return .gray
        case .brows: return .juruTeal
        case .pucker: return .juruCoral
        case .done: return .juruGold
        }
    }

    @State private var demoTimeAccumulator: Double = 0.0

    /// Updates the avatar demo animation loop.
    ///
    /// Runs a 2.5-second cycle showing the user what gesture to perform:
    /// - 0.0-0.5s: Relaxed state
    /// - 0.5-1.5s: Active gesture (brow raise or pucker)
    /// - 1.5-2.5s: Return to relaxed
    ///
    /// - Parameter elapsed: Time since last update (should be ~50ms)
    func updateDemoLoop(elapsed: TimeInterval) {
        demoTimeAccumulator += elapsed

        if currentStep == .brows {
            let cycle = demoTimeAccumulator.truncatingRemainder(dividingBy: 2.5)
            if cycle < 0.5 {
                withAnimation(.spring(response: 0.4)) { animBrow = 0.0 }
            } else if cycle < 1.5 {
                withAnimation(.spring(response: 0.3)) { animBrow = 1.0 }
            } else {
                withAnimation(.spring(response: 0.4)) { animBrow = 0.0 }
            }
        } else if currentStep == .pucker {
            let cycle = demoTimeAccumulator.truncatingRemainder(dividingBy: 2.5)
            if cycle < 0.5 {
                withAnimation(.spring(response: 0.4)) { animPucker = 0.0 }
            } else if cycle < 1.5 {
                withAnimation(.spring(response: 0.3)) { animPucker = 1.0 }
            } else {
                withAnimation(.spring(response: 0.4)) { animPucker = 0.0 }
            }
        }
    }

    /// Collects facial data samples to establish the user's neutral baseline.
    ///
    /// Gathers 20 samples at 50ms intervals (total ~1 second) to calculate
    /// the average resting position for both eyebrow and pucker gestures.
    /// This baseline is subtracted from future readings to normalize input.
    ///
    /// - Parameter now: Current timestamp for interval control
    func collectNeutralData(now: Date) {
        let timeSinceLastCollect = now.timeIntervalSince(lastNeutralCollectTime)
        guard timeSinceLastCollect >= tickInterval else { return }
        lastNeutralCollectTime = now

        if neutralCount < 20 {
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

    /// Displays success feedback and transitions to the next calibration step.
    ///
    /// Shows a checkmark animation for 1.2 seconds, then advances to the next step.
    /// For brows and pucker steps, shows a 3-second demo before enabling user turn.
    ///
    /// - Parameter nextStep: The step to transition to after the success animation
    func triggerSuccessAndNext(to nextStep: Step) {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showSuccessFeedback = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showSuccessFeedback = false
                currentStep = nextStep
                if nextStep != .done { isUserTurn = false }
                progress = 0.0
                demoTimeAccumulator = 0.0
                animBrow = 0.0
                animPucker = 0.0
            }
            if nextStep != .done {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
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
