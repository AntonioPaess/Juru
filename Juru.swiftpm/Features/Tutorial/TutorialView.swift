//
//  TutorialView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 05/01/26.
//

import SwiftUI

struct TutorialView: View {
    @Bindable var vocabManager: VocabularyManager
    var faceManager: FaceTrackingManager
    var onTutorialComplete: () -> Void

    @Binding var currentFocus: TutorialFocus
    @Binding var allowsUndo: Bool

    // MARK: - Story Phases

    enum StoryPhase: Equatable {
        case intro

        // --- 1. LEARN MECHANICS (Watch + Do simultaneously) ---
        case learn_Navigate
        case learn_Select
        case learn_Undo

        // --- 2. TYPE "H" ---
        case type_Intro
        case type_FocusLeft
        case type_OpenLetters
        case type_SelectAM
        case type_SelectHM
        case type_SelectHJ
        case type_SelectHI
        case type_SelectH

        // --- 3. PREDICT "HELP" ---
        case predict_Intro
        case predict_FocusRight
        case predict_OpenMenu
        case predict_FindHelp

        // --- 4. SPEAK & CLEAR ---
        case speak_Intro
        case speak_OpenMenu
        case speak_SelectAction

        case clear_Intro
        case clear_FocusRight
        case clear_OpenMenu
        case clear_SelectAction

        case completed

        /// Whether this phase shows a gesture demo animation alongside user action.
        var isLearnPhase: Bool {
            switch self {
            case .learn_Navigate, .learn_Select, .learn_Undo: return true
            default: return false
            }
        }

        /// Whether this phase is an intro/transition with only text (no user action).
        var isIntroPhase: Bool {
            switch self {
            case .intro, .type_Intro, .predict_Intro, .speak_Intro, .clear_Intro, .completed:
                return true
            default: return false
            }
        }

        /// Whether undo is allowed in this phase.
        /// Only allowed in learn_Undo (where undo is taught) — blocked during guided phases.
        var allowsUndo: Bool {
            switch self {
            case .learn_Undo: return true
            default: return false
            }
        }

        /// The gesture type for learn phases.
        var gestureType: GestureDemoScene.GestureType? {
            switch self {
            case .learn_Navigate: return .navigation
            case .learn_Select: return .select
            case .learn_Undo: return .undo
            default: return nil
            }
        }

        /// SF Symbol for intro phases.
        var introIcon: String? {
            switch self {
            case .intro: return "hand.wave.fill"
            case .type_Intro: return "keyboard"
            case .predict_Intro: return "lightbulb.fill"
            case .speak_Intro: return "speaker.wave.2.fill"
            case .clear_Intro: return "xmark.circle.fill"
            case .completed: return "checkmark.seal.fill"
            default: return nil
            }
        }

        /// Section index (0-based) for progress indicator.
        var section: Int {
            switch self {
            case .intro: return 0
            case .learn_Navigate: return 1
            case .learn_Select: return 2
            case .learn_Undo: return 3
            case .type_Intro, .type_FocusLeft, .type_OpenLetters,
                 .type_SelectAM, .type_SelectHM, .type_SelectHJ,
                 .type_SelectHI, .type_SelectH: return 4
            case .predict_Intro, .predict_FocusRight, .predict_OpenMenu,
                 .predict_FindHelp: return 5
            case .speak_Intro, .speak_OpenMenu, .speak_SelectAction: return 6
            case .clear_Intro, .clear_FocusRight, .clear_OpenMenu,
                 .clear_SelectAction: return 7
            case .completed: return 8
            }
        }

        /// Total number of sections.
        static let totalSections = 9
    }

    // MARK: - State

    @State private var phase: StoryPhase = .intro
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var isSuccessFeedback: Bool = false
    @State private var isTransitioning: Bool = false
    @State private var isProcessingCheck: Bool = false
    @State private var initialFocusState: Int? = nil
    @State private var isFaceDetected: Bool = true
    @State private var lastFaceCheckTime: Date = .distantPast
    @State private var autoAdvanceTask: Task<Void, Never>?
    @State private var transitionUnlockTask: Task<Void, Never>?

    @Environment(\.horizontalSizeClass) var sizeClass
    var isPad: Bool { sizeClass == .regular }

    // MARK: - Body

    var body: some View {
        TimelineView(.periodic(from: .now, by: AppConfig.Timing.faceCheckInterval)) { timeline in
            ZStack {
                tutorialContent

                FaceNotDetectedOverlay(
                    isVisible: !isFaceDetected && phase != .completed,
                    scale: isPad ? 1.2 : 1.0
                )
            }
            .onChange(of: timeline.date) { _, _ in
                checkFaceTracking()
            }
        }
        .onAppear { startStory() }
        .onDisappear {
            autoAdvanceTask?.cancel()
            transitionUnlockTask?.cancel()
        }
        .onChange(of: faceManager.currentFocusState) { checkNavigation() }
        .onChange(of: faceManager.puckerState) { checkPucker() }
        .onChange(of: faceManager.isBackingOut) { checkUndo() }
        .onChange(of: vocabManager.leftLabel) { checkContext() }
        .onChange(of: vocabManager.rightLabel) { checkContext() }
        .onChange(of: vocabManager.currentMessage) { checkTyping() }
        .onChange(of: vocabManager.isSpeaking) { checkSpeaking() }
        .onChange(of: phase) { checkAllConditions() }
        .onChange(of: isTransitioning) { _, newValue in
            if !newValue { checkAllConditions() }
        }
    }

    // MARK: - Layout

    @ViewBuilder
    var tutorialContent: some View {
        if isPad {
            // iPad: card positioned on the leading side to avoid covering the avatar/feedback center
            HStack {
                Spacer()
                VStack {
                    instructionCard
                        .padding(.top, AppConfig.Padding.xxl)
                    Spacer()
                }
                .frame(maxWidth: AppConfig.Tutorial.iPadCardColumnWidth)
            }
            .padding(.trailing, AppConfig.Padding.xl)
        } else {
            // iPhone: card at the bottom
            VStack {
                Spacer()
                instructionCard
                    .padding(.bottom, AppConfig.Padding.tutorialCardBottomIPhone)
            }
            .padding(.horizontal, AppConfig.Padding.tutorialHorizontal(isPad: false))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Instruction Card (Apple-like)

    var instructionCard: some View {
        VStack(spacing: 0) {
            // Progress dots
            progressIndicator
                .padding(.top, AppConfig.Padding.md)

            // Intro phase: large icon
            if phase.isIntroPhase, let icon = phase.introIcon {
                Image(systemName: icon)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(
                        phase == .completed
                            ? Color.juruGold
                            : Color.juruTeal
                    )
                    .symbolEffect(.pulse, value: phase)
                    .padding(.top, AppConfig.Padding.lg)
                    .padding(.bottom, AppConfig.Padding.xs)
            }

            // Learn phase: demo animation + user performs gesture simultaneously
            if phase.isLearnPhase, let gestureType = phase.gestureType {
                GestureDemoScene(
                    gestureType: gestureType,
                    faceManager: faceManager,
                    scale: AppConfig.Tutorial.demoScale,
                    showAvatar: true
                )
                .frame(height: AppConfig.Tutorial.demoHeight)
                .padding(.top, AppConfig.Padding.lg)
                .padding(.bottom, AppConfig.Padding.sm)
            }

            // Title + Subtitle
            VStack(spacing: AppConfig.Padding.sm) {
                Text(title)
                    .font(.system(size: AppConfig.Tutorial.titleFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(isSuccessFeedback ? .white : .primary)
                    .multilineTextAlignment(.center)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: AppConfig.Tutorial.subtitleFontSize, design: .rounded))
                        .foregroundStyle(isSuccessFeedback ? .white.opacity(0.9) : .secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, AppConfig.Padding.xl)
            .padding(.top, (phase.isLearnPhase || phase.isIntroPhase)
                     ? AppConfig.Padding.sm
                     : AppConfig.Padding.xl)

            // Action hint pill
            if shouldShowAction && !isSuccessFeedback {
                HStack(spacing: 6) {
                    Image(systemName: actionIcon)
                    Text(actionText)
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.vertical, AppConfig.Padding.xs)
                .padding(.horizontal, AppConfig.Padding.lg)
                .background(actionPillColor)
                .clipShape(Capsule())
                .shadow(color: actionPillColor.opacity(0.3), radius: AppConfig.Tutorial.actionPillShadowRadius, y: AppConfig.Tutorial.actionPillShadowY)
                .padding(.top, AppConfig.Padding.md)
                .transition(.scale.combined(with: .opacity))
            }

        }
        .padding(.bottom, AppConfig.Padding.xl)
        .frame(maxWidth: AppConfig.Tutorial.cardMaxWidth)
        .background(
            RoundedRectangle(cornerRadius: AppConfig.Tutorial.cardCornerRadius, style: .continuous)
                .fill(isSuccessFeedback ? AnyShapeStyle(Color.juruTeal) : AnyShapeStyle(.regularMaterial))
                .shadow(color: Color.black.opacity(0.12), radius: 20, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConfig.Tutorial.cardCornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        )
        .id(phase)
        .transition(.push(from: .trailing))
        .animation(
            .spring(response: AppConfig.Animation.springResponse, dampingFraction: AppConfig.Animation.springDamping),
            value: phase
        )
    }

    // MARK: - Progress Indicator

    var progressIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<StoryPhase.totalSections, id: \.self) { index in
                Capsule()
                    .fill(index <= phase.section ? Color.juruTeal : Color.primary.opacity(0.15))
                    .frame(height: 3)
                    .animation(.easeInOut(duration: AppConfig.Animation.standard), value: phase.section)
            }
        }
        .padding(.horizontal, AppConfig.Padding.xl)
    }

    // MARK: - Check Functions

    private func checkFaceTracking() {
        #if DEBUG
        if DebugConfig.isEnabled { return }
        #endif

        let now = Date()
        guard now.timeIntervalSince(lastFaceCheckTime) >= AppConfig.Timing.faceCheckInterval else { return }
        lastFaceCheckTime = now

        let timeSinceFace = now.timeIntervalSince(faceManager.lastFaceDetectedTime)
        let faceVisible = timeSinceFace < AppConfig.Timing.faceDetectionTimeout

        if faceVisible != isFaceDetected {
            withAnimation { isFaceDetected = faceVisible }
        }
    }

    func checkAllConditions() {
        guard !isProcessingCheck && !isTransitioning else { return }
        isProcessingCheck = true
        defer { isProcessingCheck = false }

        checkNavigation()
        checkPucker()
        checkUndo()
        checkContext()
        checkTyping()
        checkSpeaking()
    }

    func checkNavigation() {
        if phase == .learn_Navigate {
            if let startState = initialFocusState, faceManager.currentFocusState != startState {
                advance(to: .learn_Select)
            }
        }

        if phase == .type_FocusLeft && faceManager.currentFocusState == 1 {
            advance(to: .type_OpenLetters)
        }

        if phase == .predict_FocusRight && faceManager.currentFocusState == 2 {
            advance(to: .predict_OpenMenu)
        }

        // Clear: navigate to the right menu first
        if phase == .clear_FocusRight && faceManager.currentFocusState == 2 {
            advance(to: .clear_OpenMenu)
        }
    }

    func checkPucker() {
        if phase == .learn_Select && faceManager.puckerState == .readyToSelect {
            advance(to: .learn_Undo)
        }
    }

    func checkUndo() {
        if phase == .learn_Undo && faceManager.isBackingOut {
            advance(to: .type_Intro)
        }
    }

    func checkContext() {
        let left = vocabManager.leftLabel
        let right = vocabManager.rightLabel

        updateDynamicFocus(left: left, right: right)

        switch phase {
        // Type H tree
        case .type_OpenLetters:
            if left.contains("-") || left.contains("A") { advance(to: .type_SelectAM) }
        case .type_SelectAM:
            if right.contains("H") { advance(to: .type_SelectHM) }
        case .type_SelectHM:
            if left.contains("J") || left.contains("H") { advance(to: .type_SelectHJ) }
        case .type_SelectHJ:
            if left.contains("I") || left.contains("H") { advance(to: .type_SelectHI) }
        case .type_SelectHI:
            if left == "H" { advance(to: .type_SelectH) }

        // Predict Help tree: once menu is open, just let user navigate freely
        case .predict_OpenMenu:
            if left.localizedCaseInsensitiveContains("Help")
                || left.localizedCaseInsensitiveContains("Hot")
                || left.contains("Space") {
                advance(to: .predict_FindHelp)
            }

        // Speak: open the right menu tree
        case .speak_OpenMenu:
            if right.contains("Speak") || left.contains("Speak") {
                advance(to: .speak_SelectAction)
            }

        // Clear: navigate inside the right menu tree to find "Clear All"
        case .clear_OpenMenu:
            if right.contains("Clear") || left.contains("Clear") {
                advance(to: .clear_SelectAction)
            }

        default: break
        }
    }

    func updateDynamicFocus(left: String, right: String) {
        switch phase {
        case .speak_SelectAction:
            if right.contains("Speak") { currentFocus = .rightButton }
            else if left.contains("Speak") { currentFocus = .leftButton }
            else { currentFocus = .rightButton }

        case .clear_OpenMenu, .clear_SelectAction:
            if right.contains("Clear") { currentFocus = .rightButton }
            else if left.contains("Clear") { currentFocus = .leftButton }
            else { currentFocus = .rightButton }

        default: break
        }
    }

    func checkSpeaking() {
        if vocabManager.isSpeaking && phase == .speak_SelectAction {
            advance(to: .clear_Intro, delay: AppConfig.Tutorial.speakingDelay)
        }
    }

    func checkTyping() {
        let msg = vocabManager.currentMessage

        // Skip-ahead: if Help already typed during prediction navigation
        if msg.localizedCaseInsensitiveContains("Help") {
            switch phase {
            case .predict_FindHelp:
                advance(to: .speak_Intro, delay: AppConfig.Tutorial.quickDelay)
                return
            default: break
            }
        }

        switch phase {
        case .type_SelectH:
            if msg.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("H") {
                advance(to: .predict_Intro, delay: AppConfig.Tutorial.quickDelay)
            }
        case .clear_SelectAction:
            if msg.isEmpty { advance(to: .completed) }
        default: break
        }
    }

    // MARK: - Flow Control

    func advance(to next: StoryPhase, delay: Double = 0.0) {
        guard !isTransitioning else { return }
        isTransitioning = true
        triggerSuccess()

        transitionUnlockTask?.cancel()

        if delay > 0 {
            transitionUnlockTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                setPhase(next)
                try? await Task.sleep(for: .seconds(AppConfig.Animation.slow))
                guard !Task.isCancelled else { return }
                isTransitioning = false
            }
        } else {
            setPhase(next)
            transitionUnlockTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(AppConfig.Animation.slow))
                guard !Task.isCancelled else { return }
                isTransitioning = false
            }
        }
    }

    func setPhase(_ p: StoryPhase) {
        withAnimation(.spring(response: AppConfig.Animation.springResponse, dampingFraction: AppConfig.Animation.springDamping)) {
            phase = p
            updateTexts()
        }

        // Update undo permission based on current phase
        allowsUndo = p.allowsUndo

        if p == .learn_Navigate {
            initialFocusState = faceManager.currentFocusState
        }

        updateDynamicFocus(left: vocabManager.leftLabel, right: vocabManager.rightLabel)

        // Auto-advance timers (cancellable) — only for intro/transition phases
        let autoDelay: Double? = {
            switch p {
            case .intro:          return AppConfig.Tutorial.introDelay
            case .type_Intro:     return AppConfig.Tutorial.introDelay
            case .predict_Intro:  return AppConfig.Tutorial.extendedDelay
            case .speak_Intro:    return AppConfig.Tutorial.introDelay
            case .clear_Intro:    return AppConfig.Tutorial.introDelay
            default:              return nil
            }
        }()

        let nextPhase: StoryPhase? = {
            switch p {
            case .intro:          return .learn_Navigate
            case .type_Intro:     return .type_FocusLeft
            case .predict_Intro:  return .predict_FocusRight
            case .speak_Intro:    return .speak_OpenMenu
            case .clear_Intro:    return .clear_FocusRight
            default:              return nil
            }
        }()

        if let delay = autoDelay, let next = nextPhase {
            autoAdvanceTask?.cancel()
            autoAdvanceTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled, phase == p else { return }
                setPhase(next)
            }
        }

        // Completed: trigger callback
        if p == .completed {
            autoAdvanceTask?.cancel()
            autoAdvanceTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(AppConfig.Tutorial.completionDelay))
                guard !Task.isCancelled else { return }
                onTutorialComplete()
            }
        }
    }

    func startStory() {
        vocabManager.currentMessage = ""
        setPhase(.intro)
    }

    func triggerSuccess() {
        withAnimation { isSuccessFeedback = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(AppConfig.Tutorial.successFeedback))
            withAnimation { isSuccessFeedback = false }
        }
    }

    // MARK: - Text & Focus Updates

    func updateTexts() {
        switch phase {
        case .intro:
            title = "Welcome"
            subtitle = "Let's learn how to use Juru."
            currentFocus = .none

        // Learn: Navigate (demo + user action)
        case .learn_Navigate:
            title = "Navigation"
            subtitle = "Raise your eyebrows to switch sides. Try it now!"
            currentFocus = .none

        // Learn: Select (demo + user action)
        case .learn_Select:
            title = "Selection"
            subtitle = "Pucker your lips and hold for 1 second. Try it now!"
            currentFocus = .none

        // Learn: Undo (demo + user action)
        case .learn_Undo:
            title = "Undo"
            subtitle = "Hold your pucker longer (2 seconds) to go back. Try it now!"
            currentFocus = .none

        // Type H
        case .type_Intro:
            title = "Type \"Help\""
            subtitle = "Let's spell it out. First, find the letter H."
            currentFocus = .none
        case .type_FocusLeft:
            title = "Letters"
            subtitle = "Look LEFT to find 'Letters'."
            currentFocus = .leftButton
        case .type_OpenLetters:
            title = "Open Letters"
            subtitle = "Hold Pucker to enter."
            currentFocus = .leftButton
        case .type_SelectAM:
            title = "A - M"
            subtitle = "Select the first group (Left)."
            currentFocus = .leftButton
        case .type_SelectHM:
            title = "H - M"
            subtitle = "Now look RIGHT for the H group."
            currentFocus = .rightButton
        case .type_SelectHJ:
            title = "H - J"
            subtitle = "Look LEFT to narrow down."
            currentFocus = .leftButton
        case .type_SelectHI:
            title = "H - I"
            subtitle = "Narrow down on the LEFT."
            currentFocus = .leftButton
        case .type_SelectH:
            title = "Select H"
            subtitle = "Select 'H' on the LEFT."
            currentFocus = .leftButton

        // Predict Help
        case .predict_Intro:
            title = "Prediction"
            subtitle = "Juru suggests words as you type. Look at the suggestions above your avatar."
            currentFocus = .suggestions
        case .predict_FocusRight:
            title = "Predict & Edit"
            subtitle = "Look RIGHT to select 'Predict & Edit'."
            currentFocus = .rightButton
        case .predict_OpenMenu:
            title = "Open Predict"
            subtitle = "Hold Pucker to open the menu."
            currentFocus = .rightButton
        case .predict_FindHelp:
            title = "Find \"Help\""
            subtitle = "Navigate the suggestions and select 'Help'."
            currentFocus = .leftButton

        // Speak
        case .speak_Intro:
            title = "Speak It"
            subtitle = "Let's say it out loud."
            currentFocus = .none
        case .speak_OpenMenu:
            title = "Edit Menu"
            subtitle = "Look RIGHT and open the menu."
            currentFocus = .rightButton
        case .speak_SelectAction:
            title = "Press Speak"
            subtitle = "Navigate to 'Speak' and select it."
            // Dynamic focus

        // Clear
        case .clear_Intro:
            title = "Almost Done"
            subtitle = "Let's clear the screen."
            currentFocus = .none
        case .clear_FocusRight:
            title = "Edit Menu"
            subtitle = "Look RIGHT to open 'Predict & Edit'."
            currentFocus = .rightButton
        case .clear_OpenMenu:
            title = "Find Clear All"
            subtitle = "Look RIGHT to open 'Predict & Edit'."
            // Dynamic focus
        case .clear_SelectAction:
            title = "Clear All"
            subtitle = "Select 'Clear All' to erase the text."
            // Dynamic focus

        case .completed:
            title = "Tutorial Complete"
            subtitle = "You are ready to use Juru."
            currentFocus = .none
        }
    }

    // MARK: - UI Helpers

    var shouldShowAction: Bool {
        if isSuccessFeedback { return false }
        switch phase {
        case .learn_Navigate, .learn_Select, .learn_Undo: return true
        default: return currentFocus != .none
        }
    }

    var actionIcon: String {
        switch phase {
        case .learn_Navigate: return "eyebrow"
        case .learn_Select: return "mouth.fill"
        case .learn_Undo: return "clock.arrow.circlepath"
        default: return "cursorarrow.click"
        }
    }

    var actionText: String {
        switch phase {
        case .learn_Navigate: return "Raise Brows"
        case .learn_Select: return "Pucker & Hold"
        case .learn_Undo: return "Long Pucker (Red)"
        default: return "Select"
        }
    }

    var actionPillColor: Color {
        switch phase {
        case .learn_Undo: return .juruCoral
        default: return .juruTeal
        }
    }
}
