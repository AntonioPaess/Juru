//
//  CalibrationView.swift
//  Juru
//
//  Created by Antonio Paes De Andrade on 14/12/25.
//
//  Apple-style calibration flow: neutral baseline capture, brow/pucker
//  threshold detection with demo-then-try pattern. Clean progress ring,
//  fixed typography, no scale threading.
//

import SwiftUI

struct CalibrationView: View {
    var faceManager: FaceTrackingManager
    var onCalibrationComplete: () -> Void

    enum Step: Equatable {
        case neutral, brows, pucker, done

        var color: Color {
            switch self {
            case .neutral: return .gray
            case .brows:   return .juruTeal
            case .pucker:  return .juruCoral
            case .done:    return .juruGold
            }
        }

        var title: String {
            switch self {
            case .neutral: return "Relax Your Face"
            case .brows:   return "Raise Eyebrows"
            case .pucker:  return "Pucker Lips"
            case .done:    return "All Set!"
            }
        }

        var description: String {
            switch self {
            case .neutral: return "Keep your face natural and still.\nFinding your baseline..."
            case .brows:   return "Raise your eyebrows as high as you can."
            case .pucker:  return "Make a kiss face to set your selection range."
            case .done:    return "Calibration complete.\nYour voice is ready."
            }
        }
    }

    // MARK: - State

    @State private var currentStep: Step = .neutral
    @State private var progress: CGFloat = 0.0
    @State private var isUserTurn: Bool = false
    @State private var isPreparing: Bool = true
    @State private var startCountdown: Double = AppConfig.Timing.calibrationCountdown
    @State private var showSuccessFeedback: Bool = false
    @State private var animBrow: Double = 0.0
    @State private var animPucker: Double = 0.0
    @State private var neutralCount: Int = 0
    @State private var neutralBrowSum: Double = 0
    @State private var neutralPuckerSum: Double = 0
    @State private var lastTickTime: Date = .distantPast
    @State private var lastNeutralCollectTime: Date = .distantPast
    @State private var isFaceDetected: Bool = true
    @State private var isStepTransitioning: Bool = false
    @State private var demoTimeAccumulator: Double = 0.0

    // MARK: - Body

    var body: some View {
        TimelineView(.periodic(from: .now, by: AppConfig.Timing.tickInterval)) { timeline in
            GeometryReader { geo in
                let isLandscape = geo.size.width > geo.size.height

                ZStack {
                    Color.juruBackground.ignoresSafeArea()

                    AmbientCalibrationBackground(step: currentStep)
                        .ignoresSafeArea()

                    if isLandscape {
                        landscapeLayout(geo: geo)
                    } else {
                        portraitLayout(geo: geo)
                    }

                    if isPreparing {
                        countdownOverlay
                    }

                    FaceNotDetectedOverlay(isVisible: !isFaceDetected && !isPreparing)
                        .zIndex(101)
                }
            }
            .onChange(of: timeline.date) { _, _ in
                handleTimelineTick()
            }
        }
        .onChange(of: faceManager.rawValues[.browUp]) { _, val in handleInput(Float(val ?? 0), gesture: .browUp) }
        .onChange(of: faceManager.rawValues[.pucker]) { _, val in handleInput(Float(val ?? 0), gesture: .pucker) }
        .onChange(of: faceManager.puckerState) { _, newState in
            if currentStep == .done && newState == .readyToSelect {
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
                onCalibrationComplete()
            }
        }
    }

    // MARK: - Layouts

    @ViewBuilder
    private func landscapeLayout(geo: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            // LEFT: Instructions + Controls
            VStack(spacing: 0) {
                Spacer()

                CalibrationInstructionText(
                    step: currentStep,
                    align: .leading
                )

                Spacer().frame(height: AppConfig.Padding.xxxl)

                CalibrationControlsView(
                    currentStep: currentStep,
                    isUserTurn: isUserTurn,
                    puckerProgress: currentStep == .done ? faceManager.interactionProgress : 0,
                    onAction: onCalibrationComplete
                )

                Spacer()
            }
            .frame(width: geo.size.width * AppConfig.Layout.landscapeLeftPanelWidth)
            .padding(.leading, AppConfig.Padding.landscapeSideMargin)

            // RIGHT: Avatar + Ring
            CalibrationAvatarHero(
                faceManager: faceManager,
                progress: progress,
                animBrow: isUserTurn ? nil : animBrow,
                animPucker: isUserTurn ? nil : animPucker,
                showSuccessFeedback: showSuccessFeedback,
                stepColor: currentStep.color
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func portraitLayout(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()

            CalibrationAvatarHero(
                faceManager: faceManager,
                progress: progress,
                animBrow: isUserTurn ? nil : animBrow,
                animPucker: isUserTurn ? nil : animPucker,
                showSuccessFeedback: showSuccessFeedback,
                stepColor: currentStep.color
            )
            .padding(.top, AppConfig.Padding.xxxl)

            Spacer()

            VStack(spacing: AppConfig.Padding.xxl) {
                CalibrationInstructionText(
                    step: currentStep,
                    align: .center
                )
                .padding(.horizontal, AppConfig.Padding.xxl)

                CalibrationControlsView(
                    currentStep: currentStep,
                    isUserTurn: isUserTurn,
                    puckerProgress: currentStep == .done ? faceManager.interactionProgress : 0,
                    onAction: onCalibrationComplete
                )
            }
            .padding(.bottom, AppConfig.Padding.huge)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask(LinearGradient(
                        colors: [.clear, .black, .black],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .ignoresSafeArea()
                    .padding(.top, -100)
            )
        }
    }

    // MARK: - Countdown Overlay

    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: AppConfig.Padding.lg) {
                Text("Get Ready")
                    .font(.system(
                        size: AppConfig.Onboarding.titleFontSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundStyle(.white.opacity(0.9))

                Text("\(Int(startCountdown))")
                    .font(.system(
                        size: AppConfig.Calibration.countdownFontSize,
                        weight: .heavy,
                        design: .rounded
                    ))
                    .foregroundStyle(Color.juruTeal)
                    .contentTransition(.numericText())
                    .shadow(color: Color.juruTeal.opacity(0.3), radius: 12)
                    .id(Int(startCountdown))
            }
            .transition(.scale.combined(with: .opacity))
        }
        .zIndex(100)
    }

    // MARK: - Timeline Tick

    private func handleTimelineTick() {
        let now = Date.now
        let elapsed = now.timeIntervalSince(lastTickTime)
        guard elapsed >= AppConfig.Timing.tickInterval else { return }
        lastTickTime = now

        if isPreparing {
            if startCountdown > 1.0 {
                withAnimation(.linear(duration: AppConfig.Timing.tickInterval)) {
                    startCountdown -= AppConfig.Timing.tickInterval
                }
            } else {
                withAnimation(.easeOut(duration: AppConfig.Animation.standard)) {
                    isPreparing = false
                }
            }
        } else {
            checkFaceTracking(now: now)

            if currentStep == .neutral {
                collectNeutralData(now: now)
            } else if !isUserTurn && (currentStep == .brows || currentStep == .pucker) {
                updateDemoLoop(elapsed: AppConfig.Timing.tickInterval)
            }
        }
    }

    // MARK: - Face Tracking Check

    private func checkFaceTracking(now: Date) {
        guard currentStep != .done else {
            if !isFaceDetected { isFaceDetected = true }
            return
        }

        let timeSinceFace = now.timeIntervalSince(faceManager.lastFaceDetectedTime)
        let faceVisible = timeSinceFace < AppConfig.Timing.faceDetectionTimeout

        if faceVisible != isFaceDetected {
            withAnimation { isFaceDetected = faceVisible }
        }
    }

    // MARK: - Demo Animation

    private func updateDemoLoop(elapsed: TimeInterval) {
        demoTimeAccumulator += elapsed
        let cycle = demoTimeAccumulator.truncatingRemainder(dividingBy: AppConfig.Timing.demoCycleDuration)

        let targetValue: Double = (cycle >= 0.5 && cycle < 1.5) ? 1.0 : 0.0
        let response = targetValue > 0 ? 0.3 : 0.4

        if currentStep == .brows {
            withAnimation(.spring(response: response)) { animBrow = targetValue }
        } else if currentStep == .pucker {
            withAnimation(.spring(response: response)) { animPucker = targetValue }
        }
    }

    // MARK: - Neutral Data Collection

    private func collectNeutralData(now: Date) {
        let timeSinceLastCollect = now.timeIntervalSince(lastNeutralCollectTime)
        guard timeSinceLastCollect >= AppConfig.Timing.tickInterval else { return }
        lastNeutralCollectTime = now

        guard isFaceDetected else { return }

        let browVal = faceManager.rawValues[.browUp] ?? 0
        let puckerVal = faceManager.rawValues[.pucker] ?? 0

        if neutralCount < AppConfig.Calibration.neutralSampleCount {
            neutralBrowSum += browVal
            neutralPuckerSum += puckerVal
            neutralCount += 1
            withAnimation {
                progress = CGFloat(neutralCount) / CGFloat(AppConfig.Calibration.neutralSampleCount)
            }
        } else {
            let avgBrow = Float(neutralBrowSum / Double(neutralCount))
            let avgPucker = Float(neutralPuckerSum / Double(neutralCount))
            faceManager.setRestingBase(for: .browUp, value: avgBrow)
            faceManager.setRestingBase(for: .pucker, value: avgPucker)
            triggerSuccessAndNext(to: .brows)
        }
    }

    // MARK: - Step Transitions

    private func triggerSuccessAndNext(to nextStep: Step) {
        guard !isStepTransitioning else { return }
        isStepTransitioning = true

        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)

        withAnimation(.spring(response: AppConfig.Animation.springResponse, dampingFraction: 0.6)) {
            showSuccessFeedback = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.Timing.successFeedbackDuration) {
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
                DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.Timing.demoToUserTurnDelay) {
                    withAnimation { isUserTurn = true }
                    isStepTransitioning = false
                }
            } else {
                isStepTransitioning = false
            }
        }
    }

    // MARK: - Input Handling

    private func handleInput(_ val: Float, gesture: FaceGesture) {
        guard isUserTurn else { return }

        let base = faceManager.calibration.restingBase[gesture] ?? 0.0
        let corrected = Double(val) - base
        let correct = (currentStep == .brows && gesture == .browUp)
            || (currentStep == .pucker && gesture == .pucker)

        if correct && corrected > AppConfig.Thresholds.minCalibrationValue {
            faceManager.setCalibrationMax(for: gesture, value: val)
            withAnimation(.linear(duration: AppConfig.Animation.quick)) { progress += 0.02 }
            if progress >= 1.0 { completeStep() }
        }
    }

    private func completeStep() {
        isUserTurn = false
        if currentStep == .brows { triggerSuccessAndNext(to: .pucker) }
        else if currentStep == .pucker { triggerSuccessAndNext(to: .done) }
    }
}

// MARK: - Instruction Text

private struct CalibrationInstructionText: View {
    let step: CalibrationView.Step
    let align: TextAlignment

    var body: some View {
        VStack(
            alignment: align == .leading ? .leading : .center,
            spacing: AppConfig.Padding.md
        ) {
            Text(step.title)
                .font(.system(
                    size: AppConfig.Onboarding.titleFontSize,
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundStyle(step.color)
                .transition(.push(from: .trailing))
                .id("cal-title-\(step)")

            Text(step.description)
                .font(.system(
                    size: AppConfig.Onboarding.subtitleFontSize,
                    weight: .regular,
                    design: .rounded
                ))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(align)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .transition(.push(from: .trailing))
                .id("cal-desc-\(step)")
        }
        .frame(maxWidth: AppConfig.Onboarding.maxContentWidth)
    }
}

// MARK: - Avatar Hero Area

private struct CalibrationAvatarHero: View {
    var faceManager: FaceTrackingManager
    let progress: CGFloat
    let animBrow: Double?
    let animPucker: Double?
    let showSuccessFeedback: Bool
    let stepColor: Color

    var body: some View {
        ZStack {
            // Track ring
            Circle()
                .stroke(
                    Color.primary.opacity(AppConfig.Calibration.progressRingTrackOpacity),
                    lineWidth: AppConfig.Calibration.progressRingStrokeWidth
                )
                .frame(
                    width: AppConfig.Calibration.ringSize,
                    height: AppConfig.Calibration.ringSize
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    stepColor,
                    style: StrokeStyle(
                        lineWidth: AppConfig.Calibration.progressRingStrokeWidth,
                        lineCap: .round
                    )
                )
                .frame(
                    width: AppConfig.Calibration.ringSize,
                    height: AppConfig.Calibration.ringSize
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: stepColor.opacity(0.3), radius: 8)
                .animation(.linear(duration: AppConfig.Animation.quick), value: progress)

            // Avatar
            JuruAvatarView(
                faceManager: faceManager,
                manualBrowUp: animBrow,
                manualPucker: animPucker,
                size: AppConfig.Calibration.avatarSize
            )
            .opacity(showSuccessFeedback ? 0.3 : 1.0)
            .blur(radius: showSuccessFeedback ? 12 : 0)

            // Success checkmark
            if showSuccessFeedback {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: AppConfig.Calibration.successIconSize))
                    .foregroundStyle(.white)
                    .shadow(color: stepColor.opacity(0.5), radius: 16)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - Controls View

private struct CalibrationControlsView: View {
    let currentStep: CalibrationView.Step
    let isUserTurn: Bool
    let puckerProgress: Double
    let onAction: () -> Void

    @State private var isPulsing = false

    private var isPuckering: Bool { puckerProgress > 0.01 }

    var body: some View {
        Group {
            switch currentStep {
            case .done:
                doneSection
            case .neutral:
                statusPill(
                    icon: "circle.dotted",
                    text: "Calibrating...",
                    showSpinner: true
                )
            default:
                statusPill(
                    icon: isUserTurn ? "record.circle.fill" : "eye.fill",
                    text: isUserTurn ? "Your Turn" : "Watch Juru",
                    tint: isUserTurn ? currentStep.color : nil
                )
            }
        }
    }

    private var doneSection: some View {
        VStack(spacing: AppConfig.Padding.sm) {
            Button(action: onAction) {
                Text("Continue to Tutorial")
                    .font(.system(
                        size: AppConfig.Onboarding.subtitleFontSize,
                        weight: .semibold,
                        design: .rounded
                    ))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppConfig.Onboarding.buttonHeight)
                    .background(
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                // Base
                                RoundedRectangle(
                                    cornerRadius: AppConfig.Onboarding.buttonCornerRadius,
                                    style: .continuous
                                )
                                .fill(Color.juruTeal)

                                // Pucker fill overlay
                                RoundedRectangle(
                                    cornerRadius: AppConfig.Onboarding.buttonCornerRadius,
                                    style: .continuous
                                )
                                .fill(Color.white.opacity(0.25))
                                .frame(width: geo.size.width * CGFloat(puckerProgress))
                                .animation(.linear(duration: AppConfig.Timing.tickInterval), value: puckerProgress)
                            }
                        }
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppConfig.Onboarding.buttonCornerRadius,
                            style: .continuous
                        )
                    )
                    .shadow(
                        color: Color.juruTeal.opacity(isPuckering ? 0.6 : (isPulsing ? 0.5 : 0.2)),
                        radius: isPuckering ? 24 : (isPulsing ? 20 : 10),
                        y: 4
                    )
                    .scaleEffect(isPuckering ? 1.04 : (isPulsing ? 1.02 : 1.0))
                    .animation(.spring(response: AppConfig.Animation.springResponse), value: isPuckering)
            }
            .frame(maxWidth: AppConfig.Onboarding.maxButtonWidth)

            HStack(spacing: 6) {
                Text("Tap or")
                    .foregroundStyle(.secondary)
                Image(systemName: "mouth.fill")
                    .foregroundStyle(Color.juruTeal)
                Text("pucker to continue")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 13, weight: .medium, design: .rounded))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }

    private func statusPill(
        icon: String,
        text: String,
        showSpinner: Bool = false,
        tint: Color? = nil
    ) -> some View {
        HStack(spacing: AppConfig.Padding.sm) {
            if showSpinner {
                ProgressView()
                    .tint(.secondary)
            } else {
                Image(systemName: icon)
                    .symbolEffect(.bounce, value: isUserTurn)
                    .font(.system(size: AppConfig.Calibration.statusIconSize, weight: .semibold))
            }

            Text(text)
                .font(.system(
                    size: AppConfig.Calibration.statusFontSize,
                    weight: .semibold,
                    design: .rounded
                ))
        }
        .foregroundStyle(tint != nil ? .white : .secondary)
        .padding(.horizontal, AppConfig.Padding.xl)
        .padding(.vertical, AppConfig.Padding.sm)
        .background {
            if let tint {
                Capsule().fill(tint)
            } else {
                Capsule().fill(.ultraThinMaterial)
            }
        }
        .animation(.spring(response: AppConfig.Animation.springResponse), value: isUserTurn)
    }
}

// MARK: - Ambient Background

private struct AmbientCalibrationBackground: View {
    let step: CalibrationView.Step

    var body: some View {
        RadialGradient(
            colors: [
                step.color.opacity(0.08),
                Color.clear
            ],
            center: .center,
            startRadius: 50,
            endRadius: 500
        )
        .animation(.easeInOut(duration: 1.0), value: step)
    }
}
