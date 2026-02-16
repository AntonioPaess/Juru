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
    
    enum StoryPhase: Equatable {
        case intro
        
        // --- 1. MECÂNICAS BÁSICAS ---
        case mech_Brows     // Navegar
        case mech_Pucker    // Selecionar
        case mech_Undo      // Voltar
        
        // --- 2. QUICK WORDS (Pain) ---
        case quick_Intro        // "Cenário: Sentindo dor"
        case quick_FocusRoot    // "Olhe Direita (Quick Words)"
        case quick_OpenRoot     // "Abra o menu"
        
        case quick_FocusGroup   // "Pain está na Direita"
        case quick_SelectGroup  // "Selecione o grupo"
        
        case quick_FocusFinal   // "Agora Pain está na Esquerda"
        case quick_SelectPain   // "Selecione Pain"
        
        // --- 3. DIGITAR "H" ---
        case type_Intro         // "Agora vamos digitar H"
        case type_FocusLeft     // "Letters (Esq)"
        case type_OpenLetters   // "Abra Letters"
        case type_SelectAM      // "A - M (Esq)"
        case type_SelectHM      // "H - M (Dir)"
        case type_SelectHM_Dup  // (Mantido para compatibilidade de enum)
        case type_SelectHJ      // "H - J (Esq)"
        case type_SelectHI      // "H - I (Esq)"
        case type_SelectH       // "Selecione H (Esq)"
        
        // --- 4. PREDICT "HELP" ---
        case predict_Intro      // "Veja sugestões acima do Avatar"
        case predict_FocusRight // "Olhe Direita (Predict & Edit)"
        case predict_OpenMenu   // "Abra Predict"
        
        // Passo 1
        case predict_FocusL1    // "Olhe Esquerda (Help, Hot, Space)"
        case predict_SelectL1   // "Abra esse grupo"
        
        // Passo 2
        case predict_FocusL2    // "Olhe Esquerda (Help, Hot)"
        case predict_SelectL2   // "Selecione Help"
        
        // Passo 3
        case predict_FocusFinal // "Olhe Esquerda (Help)"
        case predict_SelectHelp // "Confirme Help"
        
        // --- 5. CORREÇÃO (Hel) ---
        case mistake_Intro      // "Ops, queríamos Hello!"
        case delete_Space       // "Segure Pucker (Vermelho) para apagar espaço"
        case delete_P           // "Segure Pucker (Vermelho) para apagar P"
        
        // --- 6. PREDICT "HELLO" ---
        case fix_Intro          // "Agora 'Hel' sugere Hello"
        case fix_FocusRight     // "Olhe Direita (Predict)"
        case fix_OpenMenu       // "Abra o menu"
        
        // Passo 1: Grupo Grande
        case fix_FocusL1        // "Olhe Esquerda (Hello está aqui)"
        case fix_SelectL1       // "Selecione o grupo"
        
        // Passo 2: Grupo Médio
        case fix_FocusL2        // "Olhe Esquerda de novo"
        case fix_SelectL2       // "Selecione o grupo"
        
        // Passo 3: FINAL NA DIREITA
        case fix_FocusFinal     // "Olhe DIREITA (Hello)"
        case fix_SelectHello    // "Confirme Hello"
        
        // --- 7. SPEAK & CLEAR ---
        case speak_Intro        // "Vamos falar"
        case speak_OpenMenu     // "Abra menu Direita"
        case speak_SelectAction // "Selecione Speak" (DINÂMICO)
        
        case clear_Intro        // "Limpar tela"
        case clear_SelectAction // "Selecione Clear" (DINÂMICO)
        
        case completed
    }
    
    @State private var phase: StoryPhase = .intro
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var isSuccessFeedback: Bool = false
    @State private var isTransitioning: Bool = false

    /// Prevents reentrant calls to checkAllConditions() that could cause infinite loops
    /// when onChange triggers modify state that triggers more onChange events.
    @State private var isProcessingCheck: Bool = false

    @State private var initialFocusState: Int? = nil

    /// Tracks whether ARKit is currently detecting a face.
    @State private var isFaceDetected: Bool = true

    /// Timestamp of last face tracking check to throttle verification to 200ms intervals.
    @State private var lastFaceCheckTime: Date = .distantPast

    @Environment(\.horizontalSizeClass) var sizeClass
    var isPad: Bool { sizeClass == .regular }

    private let faceCheckInterval: TimeInterval = AppConfig.Timing.faceCheckInterval

    var body: some View {
        TimelineView(.periodic(from: .now, by: AppConfig.Timing.faceCheckInterval)) { timeline in
            ZStack {
                tutorialContent

                FaceNotDetectedOverlay(isVisible: !isFaceDetected && phase != .completed, scale: isPad ? 1.2 : 1.0)
            }
            .onChange(of: timeline.date) { _, _ in
                checkFaceTracking()
            }
        }
        .onAppear { startStory() }

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

    @ViewBuilder
    var tutorialContent: some View {
        VStack {
            if isPad {
                instructionCard.padding(.top, AppConfig.Padding.xxxl)
                Spacer()
            } else {
                Spacer()
                instructionCard.padding(.bottom, AppConfig.Padding.tutorialCardBottomIPhone)
            }
        }
        .padding(.horizontal, AppConfig.Padding.tutorialHorizontal(isPad: isPad))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Performs all tutorial state checks in sequence with reentrancy protection.
    /// Uses isProcessingCheck flag to prevent infinite loops from onChange triggers.
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
    
    var instructionCard: some View {
        VStack(spacing: AppConfig.Padding.md) {
            HStack(spacing: AppConfig.Padding.sm) {
                Image(systemName: iconForPhase)
                    .font(.title)
                    .foregroundStyle(isSuccessFeedback ? .white : Color.juruTeal)
                    .symbolEffect(.bounce, value: phase)
                
                Text(title)
                    .font(.juruFont(.title2, weight: .bold))
                    .foregroundStyle(isSuccessFeedback ? .white : Color.juruText)
                    .multilineTextAlignment(.center)
                    .animation(.default, value: title)
            }
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.juruFont(.body))
                    .foregroundStyle(isSuccessFeedback ? .white.opacity(0.9) : Color.juruSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.default, value: subtitle)
            }
            
            if shouldShowAction && !isSuccessFeedback {
                HStack(spacing: 6) {
                    Image(systemName: actionIcon)
                    Text(actionText)
                }
                .font(.juruFont(.callout, weight: .bold))
                .foregroundStyle(.white)
                .padding(.vertical, AppConfig.Padding.xs)
                .padding(.horizontal, AppConfig.Padding.lg)
                .background(Color.juruTeal)
                .clipShape(Capsule())
                .shadow(color: .juruTeal.opacity(0.3), radius: 5, y: 2)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(AppConfig.Padding.xl)
        .background(
            RoundedRectangle(cornerRadius: AppConfig.CornerRadius.md)
                .fill(isSuccessFeedback ? AnyShapeStyle(Color.juruTeal) : AnyShapeStyle(Material.regular))
                .shadow(color: Color.black.opacity(0.1), radius: 15, y: 5)
        )
        .animation(.spring(response: AppConfig.Animation.springResponse, dampingFraction: AppConfig.Animation.springDamping), value: phase)
    }
    
    // MARK: - Lógica de Verificação
    
    func checkNavigation() {
        if phase == .mech_Brows {
            if let startState = initialFocusState, faceManager.currentFocusState != startState {
                advance(to: .mech_Pucker)
            }
        }
        
        // 2. Navegação Guiada
        if phase == .quick_FocusRoot && faceManager.currentFocusState == 2 { advance(to: .quick_OpenRoot) }
        if phase == .quick_FocusGroup && faceManager.currentFocusState == 2 { advance(to: .quick_SelectGroup) }
        if phase == .quick_FocusFinal && faceManager.currentFocusState == 1 { advance(to: .quick_SelectPain) }
        
        if phase == .type_FocusLeft && faceManager.currentFocusState == 1 { advance(to: .type_OpenLetters) }
        
        // PREDICT (Help)
        if phase == .predict_FocusRight && faceManager.currentFocusState == 2 { advance(to: .predict_OpenMenu) }
        if phase == .predict_FocusL1 && faceManager.currentFocusState == 1 { advance(to: .predict_SelectL1) }
        if phase == .predict_FocusL2 && faceManager.currentFocusState == 1 { advance(to: .predict_SelectL2) }
        if phase == .predict_FocusFinal && faceManager.currentFocusState == 1 { advance(to: .predict_SelectHelp) }
        
        // PREDICT (Hello)
        if phase == .fix_FocusRight && faceManager.currentFocusState == 2 { advance(to: .fix_OpenMenu) }
        if phase == .fix_FocusL1 && faceManager.currentFocusState == 1 { advance(to: .fix_SelectL1) }
        if phase == .fix_FocusL2 && faceManager.currentFocusState == 1 { advance(to: .fix_SelectL2) }
        if phase == .fix_FocusFinal && faceManager.currentFocusState == 2 { advance(to: .fix_SelectHello) }
    }
    
    func checkPucker() {
        if phase == .mech_Pucker && faceManager.puckerState == .readyToSelect {
            advance(to: .mech_Undo)
        }
    }
    
    func checkUndo() {
        if phase == .mech_Undo && faceManager.isBackingOut {
            advance(to: .quick_Intro)
        }
        if (phase == .delete_Space || phase == .delete_P) && faceManager.isBackingOut {
            triggerSuccess()
        }
    }
    
    func checkContext() {
        let left = vocabManager.leftLabel
        let right = vocabManager.rightLabel
        
        // ATUALIZAÇÃO DE FOCO DINÂMICO
        // Importante: Se os labels mudarem (navegação na árvore), o foco precisa atualizar
        // para permitir que o usuário continue clicando até achar "Speak" ou "Clear".
        updateDynamicFocus(left: left, right: right)
        
        switch phase {
        // Quick Words
        case .quick_OpenRoot:
            if right.contains("Pain") || right.contains("Water") { advance(to: .quick_FocusGroup) }
        case .quick_SelectGroup:
            if left == "Pain" { advance(to: .quick_FocusFinal) }
            
        // Type H
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
            
        // Predict Help
        case .predict_OpenMenu:
            if left.localizedCaseInsensitiveContains("Help") || left.localizedCaseInsensitiveContains("Hot") || left.contains("Space") {
                advance(to: .predict_FocusL1)
            }
        case .predict_SelectL1:
            if right.contains("Space") { advance(to: .predict_FocusL2) }
        case .predict_SelectL2:
            if right.localizedCaseInsensitiveContains("Hot") || left.localizedCaseInsensitiveContains("Help") {
                advance(to: .predict_FocusFinal)
            }
            
        // Predict Hello
        case .fix_OpenMenu:
            if left.localizedCaseInsensitiveContains("Hello") || right.contains("Clear") || right.contains("Speak") {
                advance(to: .fix_FocusL1)
            }
        case .fix_SelectL1:
            if right.contains("Space") || left.localizedCaseInsensitiveContains("Hello") {
                advance(to: .fix_FocusL2)
            }
            
        case .fix_SelectL2:
            if right.localizedCaseInsensitiveContains("hello") {
                advance(to: .fix_FocusFinal)
            }
            
        // Speak
        case .speak_OpenMenu:
            if right.contains("Speak") { advance(to: .speak_SelectAction) }
            
        default: break
        }
    }
    
    // NOVO: Função auxiliar para atualizar foco em tempo real
    func updateDynamicFocus(left: String, right: String) {
        switch phase {
        case .speak_SelectAction:
            if right.contains("Speak") { currentFocus = .rightButton }
            else if left.contains("Speak") { currentFocus = .leftButton }
            else { currentFocus = .rightButton } // Assume direita se não visível (grupo pai)
            
        case .clear_SelectAction:
            if right.contains("Clear") { currentFocus = .rightButton }
            else if left.contains("Clear") { currentFocus = .leftButton }
            else { currentFocus = .rightButton } // Assume direita se não visível
            
        default:
            break
        }
    }
    
    func checkSpeaking() {
        if vocabManager.isSpeaking {
            if phase == .quick_SelectPain {
                advance(to: .type_Intro, delay: AppConfig.Timing.tutorialSpeakingDelay)
            } else if phase == .speak_SelectAction {
                advance(to: .clear_Intro, delay: AppConfig.Timing.tutorialSpeakingDelay)
            }
        }
    }
    
    func checkTyping() {
        let msg = vocabManager.currentMessage
        
        if msg.localizedCaseInsensitiveContains("Help") {
            switch phase {
            case .predict_FocusL1, .predict_SelectL1, .predict_FocusL2, .predict_SelectL2, .predict_FocusFinal, .predict_SelectHelp:
                advance(to: .mistake_Intro, delay: AppConfig.Timing.tutorialQuickDelay)
                return
            default: break
            }
        }

        if msg.localizedCaseInsensitiveContains("Hello") {
            switch phase {
            case .fix_FocusRight, .fix_OpenMenu, .fix_FocusL1, .fix_SelectL1, .fix_FocusL2, .fix_SelectL2, .fix_FocusFinal, .fix_SelectHello:
                advance(to: .speak_Intro, delay: AppConfig.Timing.tutorialQuickDelay)
                return
            default: break
            }
        }

        switch phase {
        case .type_SelectH:
            if msg.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("H") {
                advance(to: .predict_Intro, delay: AppConfig.Timing.tutorialQuickDelay)
            }
        case .delete_Space:
            if msg.localizedCaseInsensitiveContains("Help") { advance(to: .delete_P) }
        case .delete_P:
            if msg == "Hel" { advance(to: .fix_Intro) }
        case .clear_SelectAction:
            if msg.isEmpty { advance(to: .completed) }
        default: break
        }
    }
    
    // --- CONTROLE DE FLUXO ---
    
    func advance(to next: StoryPhase, delay: Double = 0.0) {
        isTransitioning = true
        triggerSuccess()
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            setPhase(next)
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.Animation.slow) {
                self.isTransitioning = false
            }
        }
    }
    
    func setPhase(_ p: StoryPhase) {
        withAnimation { phase = p; updateTexts() }
        
        if p == .mech_Brows {
            initialFocusState = faceManager.currentFocusState
        }
        
        // Chamada inicial para garantir foco correto ao entrar na fase
        updateDynamicFocus(left: vocabManager.leftLabel, right: vocabManager.rightLabel)
        
        switch p {
        case .intro:
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.Timing.tutorialIntroDelay) { if phase == .intro { setPhase(.mech_Brows) } }
        case .quick_Intro:
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.Timing.tutorialIntroDelay) { if phase == .quick_Intro { setPhase(.quick_FocusRoot) } }
        case .type_Intro:
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.Timing.tutorialIntroDelay) { if phase == .type_Intro { setPhase(.type_FocusLeft) } }
        case .predict_Intro:
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.Timing.tutorialExtendedDelay) { if phase == .predict_Intro { setPhase(.predict_FocusRight) } }
        case .mistake_Intro:
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.Timing.tutorialExtendedDelay) { if phase == .mistake_Intro { setPhase(.delete_Space) } }
        case .fix_Intro:
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.Timing.tutorialIntroDelay) { if phase == .fix_Intro { setPhase(.fix_FocusRight) } }
        case .speak_Intro:
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.Timing.tutorialIntroDelay) { if phase == .speak_Intro { setPhase(.speak_OpenMenu) } }
        case .clear_Intro:
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.Timing.tutorialIntroDelay) { if phase == .clear_Intro { setPhase(.clear_SelectAction) } }
        case .completed:
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.Timing.tutorialCompletionDelay) { onTutorialComplete() }
        default: break
        }
    }
    
    func startStory() {
        vocabManager.currentMessage = ""
        setPhase(.intro)
    }
    
    func triggerSuccess() {
        withAnimation { isSuccessFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.Timing.tutorialSuccessFeedback) { withAnimation { isSuccessFeedback = false } }
    }
    
    func updateTexts() {
        switch phase {
        case .intro:
            title = "Welcome"; subtitle = "Let's master Juru."
            currentFocus = .none
            
        case .mech_Brows:
            title = "Navigation"; subtitle = "Raise Brows to verify menu control."
            currentFocus = .none
        case .mech_Pucker:
            title = "Selection"; subtitle = "Hold Pucker until green to confirm."
            currentFocus = .none
        case .mech_Undo:
            title = "Undo"; subtitle = "Hold Pucker longer (Red) to go back."
            currentFocus = .none
            
        // Quick Words
        case .quick_Intro:
            title = "Scenario 1"; subtitle = "You are in pain and need help fast."
            currentFocus = .none
        case .quick_FocusRoot:
            title = "Quick Words"; subtitle = "Look RIGHT to find 'Quick Words'."
            currentFocus = .rightButton
        case .quick_OpenRoot:
            title = "Open Menu"; subtitle = "Hold Pucker to open it."
            currentFocus = .rightButton
        case .quick_FocusGroup:
            title = "Find 'Pain'"; subtitle = "Look RIGHT again. 'Pain' is in this group."
            currentFocus = .rightButton
        case .quick_SelectGroup:
            title = "Open Group"; subtitle = "Select the group to see 'Pain'."
            currentFocus = .rightButton
        case .quick_FocusFinal:
            title = "Select 'Pain'"; subtitle = "Now look LEFT. Select 'Pain' to speak."
            currentFocus = .leftButton
        case .quick_SelectPain:
            title = "Confirm"; subtitle = "Hold Pucker to say 'Pain'."
            currentFocus = .leftButton
            
        // Type H
        case .type_Intro:
            title = "Scenario 2"; subtitle = "Now let's type 'Help'."
            currentFocus = .none
        case .type_FocusLeft:
            title = "Letters"; subtitle = "Look LEFT to find 'Letters'."
            currentFocus = .leftButton
        case .type_OpenLetters:
            title = "Open Letters"; subtitle = "Hold Pucker to enter."
            currentFocus = .leftButton
        case .type_SelectAM:
            title = "A - M"; subtitle = "Select the first group (Left)."
            currentFocus = .leftButton
        case .type_SelectHM:
            title = "H - M"; subtitle = "Now look RIGHT for H group."
            currentFocus = .rightButton
        case .type_SelectHM_Dup:
            title = "H - M"; subtitle = "Now look RIGHT for H group."
            currentFocus = .rightButton
        case .type_SelectHJ:
            title = "H - J"; subtitle = "Look LEFT to narrow down (H-J)."
            currentFocus = .leftButton
        case .type_SelectHI:
            title = "H - I"; subtitle = "Narrow down on the LEFT."
            currentFocus = .leftButton
        case .type_SelectH:
            title = "Select H"; subtitle = "Select 'H' on the LEFT."
            currentFocus = .leftButton
            
        // Predict
        case .predict_Intro:
            title = "Prediction Check"; subtitle = "Look at the two words floating above your Avatar."
            currentFocus = .none
        case .predict_FocusRight:
            title = "Predict & Edit"; subtitle = "Look RIGHT to select 'Predict'."
            currentFocus = .rightButton
        case .predict_OpenMenu:
            title = "Open Predict"; subtitle = "Hold Pucker to open the menu."
            currentFocus = .rightButton
            
        case .predict_FocusL1:
            title = "Suggestions"; subtitle = "Look LEFT for 'Help, Hot, Space'."
            currentFocus = .leftButton
        case .predict_SelectL1:
            title = "Narrow Down"; subtitle = "Select to enter this group."
            currentFocus = .leftButton
            
        case .predict_FocusL2:
            title = "Almost There"; subtitle = "Look LEFT for 'Help, Hot'."
            currentFocus = .leftButton
        case .predict_SelectL2:
            title = "Select Help"; subtitle = "Choose it on the Left."
            currentFocus = .leftButton
            
        case .predict_FocusFinal:
            title = "Found It"; subtitle = "Look LEFT for 'Help'."
            currentFocus = .leftButton
        case .predict_SelectHelp:
            title = "Confirm Help"; subtitle = "Hold Pucker to finish."
            currentFocus = .leftButton
            
        // Mistake
        case .mistake_Intro:
            title = "Oops!"; subtitle = "We actually wanted 'Hello'."
            currentFocus = .none
        case .delete_Space:
            title = "Delete Space"; subtitle = "Hold Pucker (Red) to delete space."
            currentFocus = .none
        case .delete_P:
            title = "Delete 'p'"; subtitle = "Hold Pucker (Red) again to delete 'p'."
            currentFocus = .none
            
        // Fix (Hello)
        case .fix_Intro:
            title = "Fixed!"; subtitle = "Now 'Hel' predicts 'Hello'."
            currentFocus = .none
        case .fix_FocusRight:
            title = "Look Right"; subtitle = "Go back to predictions."
            currentFocus = .rightButton
        case .fix_OpenMenu:
            title = "Open Menu"; subtitle = "Open the prediction menu."
            currentFocus = .rightButton
        case .fix_FocusL1:
            title = "Hello"; subtitle = "Look LEFT. 'Hello' is in this group."
            currentFocus = .leftButton
        case .fix_SelectL1:
            title = "Select"; subtitle = "Enter the group."
            currentFocus = .leftButton
        case .fix_FocusL2:
            title = "Narrow Down"; subtitle = "Look LEFT again."
            currentFocus = .leftButton
        case .fix_SelectL2:
            title = "Select Group"; subtitle = "Hello is in this group."
            currentFocus = .leftButton
        case .fix_FocusFinal:
            title = "Found It"; subtitle = "Look RIGHT for 'Hello'."
            currentFocus = .rightButton
        case .fix_SelectHello:
            title = "Confirm Hello"; subtitle = "Finish the word."
            currentFocus = .rightButton
            
        // Speak
        case .speak_Intro:
            title = "Speak it"; subtitle = "Let's say it out loud."
            currentFocus = .none
        case .speak_OpenMenu:
            title = "Edit Menu"; subtitle = "Open the RIGHT menu."
            currentFocus = .rightButton
        case .speak_SelectAction:
            title = "Press Speak"; subtitle = "Find 'Speak' and select it."
            // Foco definido dinamicamente em updateDynamicFocus()
            
        case .clear_Intro:
            title = "Done"; subtitle = "Let's clear the screen."
            currentFocus = .none
        case .clear_SelectAction:
            title = "Press Clear"; subtitle = "Find 'Clear' in the menu."
             // Foco definido dinamicamente em updateDynamicFocus()
            
        case .completed:
            title = "Tutorial Complete"; subtitle = "You are ready."; currentFocus = .none
        }
    }
    
    // UI Helpers (mantidos iguais)...
    var shouldShowAction: Bool {
        if isSuccessFeedback { return false }
        switch phase {
        case .mech_Brows, .mech_Pucker, .mech_Undo: return true
        default: return currentFocus != .none
        }
    }
    
    var iconForPhase: String {
        switch phase {
        case .mech_Undo, .delete_Space, .delete_P: return "arrow.uturn.backward"
        case .speak_SelectAction: return "speaker.wave.2.fill"
        case .completed: return "star.fill"
        case .predict_Intro: return "eye"
        default: return "face.smiling"
        }
    }
    
    var actionIcon: String {
        if phase == .mech_Brows { return "eyebrow" }
        if phase == .mech_Pucker { return "mouth" }
        if phase == .mech_Undo || phase == .delete_Space { return "clock.arrow.circlepath" }
        return "cursorarrow.click"
    }
    
    var actionText: String {
        if phase == .mech_Brows { return "Raise & Hold" }
        if phase == .mech_Pucker { return "Pucker (Green)" }
        if phase == .mech_Undo { return "Long Pucker (Red)" }
        return "Select Button"
    }
}
