//
//  OnboardingView.swift
//  Juru
//
//  Created by Antonio Paes De Andrade on 04/01/26.
//
//

import SwiftUI

struct OnboardingView: View {
    var faceManager: FaceTrackingManager
    var onFinished: () -> Void

    enum Phase: Int, CaseIterable {
        case welcome = 0
        case identity
        case howItWorks
        case ready
    }

    @State private var currentPhase: Phase = .welcome
    @State private var autoAdvanceRemaining: Double = AppConfig.Onboarding.autoAdvanceDuration
    @State private var lastTickTime: Date = .now

    private var isAutoAdvanceActive: Bool { currentPhase != .ready }

    private var timerProgress: Double {
        guard isAutoAdvanceActive else { return 0 }
        return 1.0 - (autoAdvanceRemaining / AppConfig.Onboarding.autoAdvanceDuration)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: AppConfig.Timing.tickInterval)) { timeline in
            GeometryReader { geo in
                let isLandscape = geo.size.width > geo.size.height

                ZStack {
                    Color.juruBackground.ignoresSafeArea()

                    AmbientOnboardingBackground(phase: currentPhase)
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        topBar

                        if isLandscape {
                            landscapeLayout(geo: geo)
                        } else {
                            portraitLayout(geo: geo)
                        }
                    }
                }
            }
            .onChange(of: timeline.date) { _, _ in
                handleAutoAdvanceTick()
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: currentPhase)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        SegmentedProgressBar(
            currentPhase: currentPhase,
            progress: timerProgress
        )
        .padding(.horizontal, AppConfig.Padding.lg)
        .padding(.top, AppConfig.Padding.sm)
    }

    // MARK: - Layouts

    @ViewBuilder
    private func landscapeLayout(geo: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            // LEFT: Text + Button
            VStack(spacing: 0) {
                Spacer()

                OnboardingTextGroup(
                    phase: currentPhase,
                    title: titleText,
                    subtitle: subtitleText
                )
                .padding(.horizontal, AppConfig.Padding.xxxl)

                Spacer().frame(height: AppConfig.Padding.xxxl)

                OnboardingActionButton(
                    title: currentPhase == .ready ? "Begin Calibration" : "Continue",
                    action: nextPhase,
                    isProminent: currentPhase == .ready
                )
                .padding(.horizontal, AppConfig.Padding.xxxl)

                Spacer()
            }
            .frame(width: geo.size.width * AppConfig.Layout.onboardingLeftPanelWidth)

            // RIGHT: Visual
            VisualStage(
                phase: currentPhase,
                faceManager: faceManager
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func portraitLayout(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()

            // Visual
            VisualStage(
                phase: currentPhase,
                faceManager: faceManager
            )
            .frame(height: geo.size.height * 0.35)

            Spacer()

            // Text + Button
            VStack(spacing: AppConfig.Padding.xxl) {
                OnboardingTextGroup(
                    phase: currentPhase,
                    title: titleText,
                    subtitle: subtitleText
                )
                .padding(.horizontal, AppConfig.Padding.xl)

                OnboardingActionButton(
                    title: currentPhase == .ready ? "Begin Calibration" : "Continue",
                    action: nextPhase,
                    isProminent: currentPhase == .ready
                )
                .padding(.horizontal, AppConfig.Padding.xl)
            }
            .padding(.bottom, AppConfig.Padding.huge)
        }
    }

    // MARK: - Timer

    private func handleAutoAdvanceTick() {
        let now = Date.now
        let elapsed = now.timeIntervalSince(lastTickTime)
        guard elapsed >= AppConfig.Timing.tickInterval else { return }
        lastTickTime = now

        guard isAutoAdvanceActive else { return }

        autoAdvanceRemaining -= elapsed
        if autoAdvanceRemaining <= 0 {
            nextPhase()
        }
    }

    // MARK: - Navigation

    func nextPhase() {
        if currentPhase == .ready {
            onFinished()
        } else if let next = Phase(rawValue: currentPhase.rawValue + 1) {
            currentPhase = next
            autoAdvanceRemaining = AppConfig.Onboarding.autoAdvanceDuration
            lastTickTime = .now
        }
    }

    // MARK: - Texts

    var titleText: String {
        switch currentPhase {
        case .welcome:
            return "Your Voice, Unlocked"
        case .identity:
            return "Meet Juru"
        case .howItWorks:
            return "Face-Powered Typing"
        case .ready:
            return "Let's Calibrate"
        }
    }

    var subtitleText: String {
        switch currentPhase {
        case .welcome:
            return "For those whose bodies have gone quiet, but whose minds remain vibrant. Juru transforms facial gestures into words and speech."
        case .identity:
            return "In Tupi-Guarani, 'Juru' means Mouth — the sacred gateway of expression. Our symbol is a smile-shaped seed, ready to bloom into your new voice."
        case .howItWorks:
            return "Raise your eyebrows to navigate. Pucker your lips to select (1s) or undo (2s). Simple gestures, powerful communication."
        case .ready:
            return "First, Juru needs to learn the unique map of your face. Relax, breathe, and let's find your voice together."
        }
    }
}

// MARK: - Segmented Progress Bar

struct SegmentedProgressBar: View {
    let currentPhase: OnboardingView.Phase
    let progress: Double

    private let segmentSpacing: CGFloat = 4

    var body: some View {
        HStack(spacing: segmentSpacing) {
            ForEach(OnboardingView.Phase.allCases, id: \.self) { phase in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: AppConfig.Onboarding.progressBarHeight / 2)
                            .fill(Color.primary.opacity(0.12))

                        RoundedRectangle(cornerRadius: AppConfig.Onboarding.progressBarHeight / 2)
                            .fill(Color.primary.opacity(0.5))
                            .frame(width: fillWidth(for: phase, in: geo.size.width))
                    }
                }
                .frame(height: AppConfig.Onboarding.progressBarHeight)
            }
        }
        .animation(.linear(duration: AppConfig.Timing.tickInterval), value: progress)
    }

    private func fillWidth(for phase: OnboardingView.Phase, in totalWidth: CGFloat) -> CGFloat {
        if phase.rawValue < currentPhase.rawValue {
            return totalWidth
        } else if phase == currentPhase {
            return totalWidth * CGFloat(max(0, min(1, progress)))
        } else {
            return 0
        }
    }
}

// MARK: - Text Group

struct OnboardingTextGroup: View {
    let phase: OnboardingView.Phase
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: AppConfig.Padding.md) {
            Text(title)
                .font(.system(
                    size: AppConfig.Onboarding.titleFontSize,
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .transition(.push(from: .trailing))
                .id("title-\(phase.rawValue)")

            Text(subtitle)
                .font(.system(
                    size: AppConfig.Onboarding.subtitleFontSize,
                    weight: .regular,
                    design: .rounded
                ))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .transition(.push(from: .trailing))
                .id("subtitle-\(phase.rawValue)")
        }
        .frame(maxWidth: AppConfig.Onboarding.maxContentWidth)
    }
}

// MARK: - Action Button (Apple-Style)

struct OnboardingActionButton: View {
    let title: String
    let action: () -> Void
    var isProminent: Bool = false

    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: AppConfig.Padding.sm) {
            Button(action: action) {
                Text(title)
                    .font(.system(
                        size: AppConfig.Onboarding.subtitleFontSize,
                        weight: .semibold,
                        design: .rounded
                    ))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppConfig.Onboarding.buttonHeight)
                    .background(
                        RoundedRectangle(
                            cornerRadius: AppConfig.Onboarding.buttonCornerRadius,
                            style: .continuous
                        )
                        .fill(Color.juruTeal)
                    )
                    .shadow(
                        color: isProminent ? Color.juruTeal.opacity(isPulsing ? 0.5 : 0.2) : .clear,
                        radius: isProminent ? (isPulsing ? 20 : 10) : 0,
                        y: 4
                    )
                    .scaleEffect(isProminent && isPulsing ? 1.02 : 1.0)
            }
            .frame(maxWidth: AppConfig.Onboarding.maxButtonWidth)

            if isProminent {
                Text("Tap to begin")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .onAppear {
            guard isProminent else { return }
            withAnimation(
                .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Visual Stage

struct VisualStage: View {
    let phase: OnboardingView.Phase
    var faceManager: FaceTrackingManager

    var body: some View {
        ZStack {
            switch phase {
            case .welcome:
                WelcomeScene()
                    .transition(.opacity)
            case .identity:
                IdentityScene()
                    .transition(.opacity)
            case .howItWorks:
                HowItWorksScene()
                    .transition(.opacity)
            case .ready:
                AvatarCelebration(faceManager: faceManager)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - Visual Scenes

struct WelcomeScene: View {
    @State private var appeared = false

    var body: some View {
        Image(systemName: "waveform.and.person.filled")
            .font(.system(size: 80, weight: .light))
            .foregroundStyle(
                LinearGradient(
                    colors: [.juruTeal, .juruTeal.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .symbolEffect(.breathe, isActive: appeared)
            .scaleEffect(appeared ? 1.0 : 0.8)
            .opacity(appeared ? 1.0 : 0)
            .animation(.spring(response: 1.0, dampingFraction: 0.8), value: appeared)
            .onAppear { appeared = true }
    }
}

struct IdentityScene: View {
    @State private var appeared = false

    var body: some View {
        Image("Juru-White")
            .resizable()
            .scaledToFit()
            .frame(width: 120)
            .shadow(color: .juruTeal.opacity(0.4), radius: 40)
            .scaleEffect(appeared ? 1.0 : 0.7)
            .opacity(appeared ? 1.0 : 0)
            .animation(
                .spring(response: 0.8, dampingFraction: 0.75).delay(0.2),
                value: appeared
            )
            .onAppear { appeared = true }
    }
}

struct HowItWorksScene: View {
    @State private var appeared = false

    var body: some View {
        HStack(spacing: AppConfig.Padding.xxxl) {
            OnboardingGestureItem(
                icon: "eyebrow",
                label: "Navigate",
                delay: 0.0,
                appeared: appeared
            )
            OnboardingGestureItem(
                icon: "mouth.fill",
                label: "Select",
                delay: 0.1,
                appeared: appeared
            )
            OnboardingGestureItem(
                icon: "arrow.uturn.backward",
                label: "Undo",
                delay: 0.2,
                appeared: appeared
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

struct OnboardingGestureItem: View {
    let icon: String
    let label: String
    let delay: Double
    let appeared: Bool

    var body: some View {
        VStack(spacing: AppConfig.Padding.sm) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(Color.juruTeal)

            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8).delay(delay),
            value: appeared
        )
    }
}

struct AvatarCelebration: View {
    var faceManager: FaceTrackingManager
    @State private var appeared = false

    var body: some View {
        JuruAvatarView(
            faceManager: faceManager,
            manualBrowUp: appeared ? 0.2 : 0.0,
            manualPucker: 0.0,
            size: 200
        )
        .scaleEffect(appeared ? 1.0 : 0.8)
        .opacity(appeared ? 1.0 : 0)
        .animation(.spring(response: 1.0, dampingFraction: 0.7), value: appeared)
        .onAppear { appeared = true }
    }
}

// MARK: - Ambient Background

struct AmbientOnboardingBackground: View {
    var phase: OnboardingView.Phase

    var body: some View {
        ZStack {
            Color.juruBackground

            RadialGradient(
                colors: [
                    Color.juruTeal.opacity(0.06),
                    Color.clear
                ],
                center: .top,
                startRadius: 100,
                endRadius: 600
            )
        }
        .animation(.easeInOut(duration: 1.0), value: phase)
    }
}
