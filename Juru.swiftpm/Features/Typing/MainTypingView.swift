//
//  MainTypingView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 24/12/25.
//

import SwiftUI

/// Defines which UI element should be highlighted during the tutorial.
enum TutorialFocus: Equatable {
    case none
    case leftButton
    case rightButton
    case suggestions
    case speak
}

/// The main typing interface where users compose messages using facial gestures.
///
/// This view displays:
/// - A text display card showing the current message being composed
/// - Word suggestions based on the current input
/// - An avatar with gesture intensity gauges
/// - Left and right action cards for menu navigation
///
/// ## Architecture
/// Uses `TimelineView` for the update loop to prevent memory leaks from traditional timers.
/// The 50ms tick rate (20Hz) matches the ARKit face tracking update frequency.
///
/// ## Tutorial Integration
/// When `isTutorialActive` is true, only specific actions are allowed based on
/// `tutorialFocus`, guiding users through the learning process step by step.
struct MainTypingView: View {
    @Bindable var vocabManager: VocabularyManager
    var faceManager: FaceTrackingManager
    var isPaused: Bool

    var tutorialFocus: TutorialFocus = .none
    var isTutorialActive: Bool

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var sizeClass

    /// Tracks whether ARKit is currently detecting a face. Shows overlay when false.
    @State private var isFaceDetected: Bool = true

    /// Timestamp of last face tracking check to throttle verification to 200ms intervals.
    @State private var lastFaceCheckTime: Date = .distantPast

    var isPad: Bool { sizeClass == .regular }

    private let faceCheckInterval: TimeInterval = AppConfig.Timing.faceCheckInterval

    var body: some View {
        TimelineView(.periodic(from: .now, by: AppConfig.Timing.tickInterval)) { timeline in
            ZStack {
                AmbientBackground()

                VStack(spacing: 0) {
                // HEADER
                HStack {
                    Image("Juru-White")
                        .resizable()
                        .scaledToFit()
                        .frame(width: AppConfig.Padding.xxxl, height: AppConfig.Padding.xxxl)
                        .shadow(color: .juruTeal.opacity(0.5), radius: 8)
                    
                    Spacer()
                    
                    if faceManager.puckerState == .readyToBack {
                        Label("Release to Undo", systemImage: "arrow.uturn.backward")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, AppConfig.Padding.sm)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .transition(.scale)
                    }
                }
                .padding(.horizontal, AppConfig.Padding.xxl)
                .padding(.top, AppConfig.Padding.lg)
                .padding(.bottom, 10)
                .opacity(shouldDim(.none) ? 0.3 : 1.0)
                
                // TEXTO
                TypingDisplayCard(text: vocabManager.currentMessage)
                    .frame(maxHeight: isPad ? AppConfig.Layout.typingCardMaxHeightIPad : AppConfig.Layout.typingCardMaxHeightIPhone)
                    .padding(.horizontal, AppConfig.Padding.horizontal(isPad: isPad))
                    .layoutPriority(1)
                    .opacity(shouldDim(.none) ? 0.3 : 1.0)
                
                // SUGESTÕES
                if !vocabManager.suggestions.isEmpty {
                    SuggestionBar(suggestions: vocabManager.suggestions)
                        .padding(.top, AppConfig.Padding.md)
                        .opacity(shouldDim(.suggestions) ? 0.3 : 1.0)
                        .overlay(
                            tutorialFocus == .suggestions ?
                            RoundedRectangle(cornerRadius: AppConfig.CornerRadius.sm)
                                .stroke(Color.juruGold, lineWidth: 3)
                                .padding(.horizontal, AppConfig.Padding.lg)
                            : nil
                        )
                }
                
                Spacer()
                
                // --- CURSOR CENTRAL ---
                ZStack {
                    FeedbackCenter(
                        faceManager: faceManager,
                        isSpeaking: vocabManager.isSpeaking
                    )
                    
                    if faceManager.puckerState != .idle && faceManager.puckerState != .cooldown {
                        ProgressRing(state: faceManager.puckerState, progress: faceManager.interactionProgress)
                            .frame(width: AppConfig.Layout.progressRingSize, height: AppConfig.Layout.progressRingSize)
                    }
                }
                .padding(.vertical, AppConfig.Padding.lg)
                .scaleEffect(isPad ? AppConfig.Scale.feedbackCenterIPad : 1.0)
                .opacity(shouldDim(.none) ? 0.5 : 1.0)
                
                Spacer()
                
                // BOTÕES DE AÇÃO
                HStack(spacing: AppConfig.Padding.xl) {
                    ActionCard(
                        title: vocabManager.leftLabel,
                        icon: "arrow.left",
                        color: .juruTeal,
                        isActive: faceManager.isTriggeringLeft,
                        alignment: .leading
                    )
                    .opacity(shouldDim(.leftButton) ? 0.3 : 1.0)
                    .overlay(
                        faceManager.currentFocusState == 1 ?
                        RoundedRectangle(cornerRadius: AppConfig.CornerRadius.lg).stroke(Color.white, lineWidth: 4) : nil
                    )
                    .scaleEffect(faceManager.currentFocusState == 1 ? 1.05 : 1.0)
                    
                    ActionCard(
                        title: vocabManager.rightLabel,
                        icon: "arrow.right",
                        color: .juruCoral,
                        isActive: faceManager.isTriggeringRight,
                        alignment: .trailing
                    )
                    .opacity(shouldDim(.rightButton) ? 0.3 : 1.0)
                    .overlay(
                        faceManager.currentFocusState == 2 ?
                        RoundedRectangle(cornerRadius: AppConfig.CornerRadius.lg).stroke(Color.white, lineWidth: 4) : nil
                    )
                    .scaleEffect(faceManager.currentFocusState == 2 ? 1.05 : 1.0)
                }
                .frame(height: AppConfig.Layout.actionCardHeight)
                .padding(.horizontal, AppConfig.Padding.horizontal(isPad: isPad))
                .padding(.bottom, AppConfig.Padding.lg)
                
                Text(footerInstruction)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.juruSecondaryText)
                    .opacity(0.6)
                    .padding(.bottom, AppConfig.Padding.lg)
            }

                FaceNotDetectedOverlay(isVisible: !isFaceDetected, scale: isPad ? 1.2 : 1.0)
            }
            .onChange(of: timeline.date) { _, _ in
                handleTimelineTick()
            }
        }
        .animation(.spring(response: AppConfig.Animation.springResponse, dampingFraction: AppConfig.Animation.springDamping), value: tutorialFocus)
    }

    /// Processes each timeline tick and updates the vocabulary manager if allowed.
    ///
    /// During tutorial mode, actions are restricted based on `tutorialFocus`:
    /// - `.leftButton`: Only allows actions when focus is on left menu
    /// - `.rightButton`: Only allows actions when focus is on right menu
    /// - Other states: Blocks all actions except undo (backing out)
    ///
    /// The undo gesture (long pucker hold) is always permitted regardless of tutorial state.
    private func handleTimelineTick() {
        guard !isPaused else { return }

        checkFaceTracking()

        var allowAction = false

        if !isTutorialActive {
            allowAction = true
        } else {
            switch tutorialFocus {
            case .leftButton:
                if faceManager.currentFocusState == 1 { allowAction = true }
            case .rightButton:
                if faceManager.currentFocusState == 2 { allowAction = true }
            case .none, .suggestions, .speak:
                allowAction = false
            }
        }

        if faceManager.isBackingOut {
            allowAction = true
        }

        if allowAction {
            vocabManager.update()
        }
    }

    /// Checks if ARKit face tracking has been lost by comparing timestamps.
    /// Shows FaceNotDetectedOverlay if no face anchor updates for > 0.5 seconds.
    private func checkFaceTracking() {
        let now = Date()
        guard now.timeIntervalSince(lastFaceCheckTime) >= faceCheckInterval else { return }
        lastFaceCheckTime = now

        let timeSinceFaceDetected = now.timeIntervalSince(faceManager.lastFaceDetectedTime)
        let faceVisible = timeSinceFaceDetected < AppConfig.Timing.faceDetectionTimeout

        if faceVisible != isFaceDetected {
            withAnimation { isFaceDetected = faceVisible }
        }
    }

    /// Returns contextual instruction text based on the current pucker state
    var footerInstruction: String {
        switch faceManager.puckerState {
        case .idle: return "Hold Pucker to Select • Long Hold to Undo"
        case .charging: return "Keep holding..."
        case .readyToSelect: return "Release to SELECT"
        case .readyToBack: return "Release to UNDO"
        case .cooldown: return "Relax..."
        }
    }
    
    func shouldDim(_ element: TutorialFocus) -> Bool {
        // Se não estiver no tutorial, não escurece nada
        if !isTutorialActive || tutorialFocus == .none { return false }
        return tutorialFocus != element
    }
}
// Structs auxiliares permanecem iguais...
struct ProgressRing: View {
    var state: PuckerState
    var progress: Double
    var ringColor: Color {
        switch state {
        case .charging: return Color.gray.opacity(0.5)
        case .readyToSelect: return Color.juruTeal
        case .readyToBack: return Color.red
        default: return .clear
        }
    }
    var iconName: String {
        switch state {
        case .readyToSelect: return "checkmark"
        case .readyToBack: return "arrow.uturn.backward"
        default: return "circle.fill"
        }
    }
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.1), lineWidth: AppConfig.Padding.xs)
            Circle().trim(from: 0.0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: AppConfig.Padding.xs, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.05), value: progress)
            if state == .readyToSelect || state == .readyToBack {
                Circle().fill(ringColor).frame(width: AppConfig.Padding.xxxl, height: AppConfig.Padding.xxxl)
                    .overlay(Image(systemName: iconName).font(.system(size: AppConfig.Padding.lg, weight: .bold)).foregroundStyle(.white))
                    .offset(y: -90).transition(.scale.combined(with: .opacity))
            }
        }
    }
}

struct AmbientBackground: View {
    var body: some View {
        ZStack {
            Color.juruBackground.ignoresSafeArea()
            GeometryReader { proxy in
                Circle().fill(Color.juruTeal.opacity(0.08)).frame(width: 600, height: 600).blur(radius: 100).offset(x: -200, y: -200)
                Circle().fill(Color.juruCoral.opacity(0.08)).frame(width: 500, height: 500).blur(radius: 100).position(x: proxy.size.width, y: proxy.size.height)
            }
        }
    }
}

struct TypingDisplayCard: View {
    var text: String
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                Text(text.isEmpty ? "Start smiling..." : text)
                    .font(.juruFont(.largeTitle, weight: .bold))
                    .foregroundStyle(text.isEmpty ? Color.secondary.opacity(0.5) : Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppConfig.Padding.xl)
                    .animation(.default, value: text)
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppConfig.CornerRadius.xl, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: AppConfig.Padding.lg, x: 0, y: 10)
        .overlay(RoundedRectangle(cornerRadius: AppConfig.CornerRadius.xl, style: .continuous).stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.5), lineWidth: 1))
    }
}

struct SuggestionBar: View {
    var suggestions: [String]
    @Environment(\.horizontalSizeClass) var sizeClass
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppConfig.Padding.sm) {
                ForEach(suggestions, id: \.self) { word in
                    Text(word)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, AppConfig.Padding.xl).padding(.vertical, 14)
                        .background(.thinMaterial).clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                }
            }
            .padding(.horizontal, AppConfig.Padding.horizontal(isPad: sizeClass == .regular)).padding(.vertical, 10)
        }
    }
}

struct FeedbackCenter: View {
    var faceManager: FaceTrackingManager
    var isSpeaking: Bool
    var activeColor: Color {
        if faceManager.currentFocusState == 1 { return .juruTeal }
        if faceManager.currentFocusState == 2 { return .juruCoral }
        return .clear
    }
    var body: some View {
        HStack(spacing: AppConfig.Padding.xxxl) {
            IntensityGauge(value: faceManager.browUp, color: .juruTeal, isLeft: true)
            ZStack {
                if isSpeaking {
                    ForEach(0..<3) { i in
                        Circle().stroke(LinearGradient(colors: [.juruTeal, .juruCoral], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                            .frame(width: AppConfig.Layout.feedbackCenterContainerSize, height: AppConfig.Layout.feedbackCenterContainerSize).scaleEffect(isSpeaking ? 2.0 : 1.0).opacity(isSpeaking ? 0.0 : 1.0)
                            .animation(.easeOut(duration: AppConfig.Animation.speakingPulse).repeatForever(autoreverses: false).delay(Double(i) * 0.4), value: isSpeaking)
                    }
                }
                if !isSpeaking {
                    Circle().fill(activeColor.opacity(0.2)).frame(width: 140, height: 140).blur(radius: AppConfig.Padding.lg)
                        .scaleEffect(activeColor == .clear ? 0.5 : 1.2).animation(.spring, value: activeColor)
                }
                Circle().fill(Color.juruCardBackground).shadow(color: Color.black.opacity(0.15), radius: 15, y: 8).frame(width: AppConfig.Layout.feedbackCenterContainerSize, height: AppConfig.Layout.feedbackCenterContainerSize)
                JuruAvatarView(faceManager: faceManager, size: AppConfig.Layout.feedbackCenterAvatarSize)
            }
            IntensityGauge(value: faceManager.mouthPucker, color: .juruCoral, isLeft: false)
        }
    }
}

struct IntensityGauge: View {
    var value: Double; var color: Color; var isLeft: Bool
    private var fillHeight: CGFloat { let visualValue = CGFloat(min(value * 1.5, 1.0)); return visualValue * AppConfig.Layout.intensityGaugeHeight }
    var body: some View {
        HStack(spacing: AppConfig.Padding.xs) {
            if isLeft { label }
            ZStack(alignment: .bottom) {
                Capsule().fill(Color.gray.opacity(0.1)).frame(width: 6, height: AppConfig.Layout.intensityGaugeHeight)
                Capsule().fill(color).frame(width: 6, height: fillHeight).shadow(color: color.opacity(0.5), radius: 4).animation(.linear(duration: AppConfig.Animation.quick), value: value)
            }
            if !isLeft { label }
        }
    }
    var label: some View { Text(isLeft ? "B" : "P").font(.caption2.bold()).foregroundStyle(Color.secondary) }
}

struct ActionCard: View {
    let title: String; let icon: String; let color: Color; let isActive: Bool; let alignment: Alignment
    var body: some View {
        ZStack(alignment: alignment) {
            RoundedRectangle(cornerRadius: AppConfig.CornerRadius.lg, style: .continuous)
                .fill(LinearGradient(colors: isActive ? [color, color.opacity(0.8)] : [Color.juruCardBackground, Color.juruCardBackground.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: isActive ? color.opacity(0.4) : Color.black.opacity(0.05), radius: isActive ? 20 : 10, y: isActive ? 10 : 5)
            VStack(alignment: alignment == .leading ? .leading : .trailing) {
                Image(systemName: icon).font(.title3).foregroundStyle(isActive ? .white : color).padding(AppConfig.Padding.sm)
                    .background(Circle().fill(isActive ? .white.opacity(0.2) : color.opacity(0.1)))
                Spacer()
                Text(title).font(.juruFont(.title2, weight: .bold)).foregroundStyle(isActive ? .white : Color.primary)
                    .multilineTextAlignment(alignment == .leading ? .leading : .trailing).lineLimit(3).minimumScaleFactor(0.4).padding(.bottom, 4)
            }
            .padding(AppConfig.Padding.xl)
        }
        .scaleEffect(isActive ? 1.02 : 1.0).animation(.spring(response: AppConfig.Animation.standard, dampingFraction: 0.6), value: isActive)
    }
}
