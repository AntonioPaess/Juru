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
    
    // Recebe o controle de foco da RootView
    @Binding var currentFocus: TutorialFocus
    
    // --- ROTEIRO EXATO ---
    enum StoryPhase {
        case intro
        
        // CENA 1: Contexto de Dor (Quick Words)
        case pain_Intro
        case pain_Start
        case pain_Nav
        case pain_Select
        
        // CENA 2: Escrita H (E -> E -> D -> E -> E -> E)
        case typeH_Intro
        case typeH_Start    // 1. Esquerda (Letters)
        case typeH_Step1    // 2. Esquerda (A-M)
        case typeH_Step2    // 3. Direita (H-M)
        case typeH_Step3    // 4. Esquerda (H-K)
        case typeH_Step4    // 5. Esquerda (H-I)
        case typeH_Step5    // 6. Esquerda (Select H)
        
        // CENA 3: Predição HELP
        case predictHelp_Intro
        case predictHelp_Start
        case predictHelp_Step1
        case predictHelp_Step2
        case predictHelp_Select
        
        // CENA 4: Correção (Bico)
        case undo_Intro
        case undo_Action
        
        // CENA 5: Predição HELLO
        case predictHello_Intro
        case predictHello_Start
        case predictHello_Step1
        case predictHello_Step2
        case predictHello_Select
        
        // CENA 6: Falar
        case speak_Intro
        case speak_Start
        case speak_Select
        
        // CENA 7: Limpar
        case clear_Intro
        case clear_Start
        case clear_Step1
        case clear_Select
        
        case completed
    }
    
    @State private var phase: StoryPhase = .intro
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var isSuccessFeedback: Bool = false
    
    @Environment(\.horizontalSizeClass) var sizeClass
    var isPad: Bool { sizeClass == .regular }
    
    var body: some View {
        VStack {
            if isPad {
                // Design Original iPad: Card no Topo
                instructionCard.padding(.top, 40)
                Spacer()
            } else {
                // Design Original iPhone: Card Embaixo
                Spacer()
                instructionCard.padding(.bottom, 130)
            }
        }
        .padding(.horizontal, isPad ? 100 : 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Overlay Transparente
        
        .onAppear { startStory() }
        
        // --- MONITORES ---
        .onChange(of: vocabManager.leftLabel) { checkNavigation() }
        .onChange(of: vocabManager.rightLabel) { checkNavigation() }
        .onChange(of: vocabManager.currentMessage) { checkMessage() }
        .onChange(of: vocabManager.isSpeaking) { checkSpeech() }
    }
    
    // MARK: - Componente Visual (Card Flutuante Original)
    var instructionCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: iconForPhase)
                    .font(.title)
                    .foregroundStyle(isSuccessFeedback ? .white : Color.juruTeal)
                    .symbolEffect(.bounce, value: phase)
                
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(isSuccessFeedback ? .white : Color.juruText)
                    .multilineTextAlignment(.center)
                    .animation(.default, value: title)
            }
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.body)
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
                .font(.callout.bold())
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(Color.juruTeal)
                .clipShape(Capsule())
                .shadow(color: .juruTeal.opacity(0.3), radius: 5, y: 2)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    isSuccessFeedback
                    ? AnyShapeStyle(Color.juruTeal)
                    : AnyShapeStyle(Material.regular)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 15, y: 5)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: phase)
        .animation(.easeInOut, value: isSuccessFeedback)
    }
    
    // MARK: - Lógica de Navegação
    func checkNavigation() {
        switch phase {
        case .pain_Start:
            if checkR("Pain") || checkR("Water") { advance(to: .pain_Nav) }
        case .pain_Nav:
            if checkL("PAIN") { advance(to: .pain_Select) }
            
        case .typeH_Start:
            if checkL("A - M") { advance(to: .typeH_Step1) }
        case .typeH_Step1:
            if checkR("H") { advance(to: .typeH_Step2) }
        case .typeH_Step2:
            if checkL("H") { advance(to: .typeH_Step3) }
        case .typeH_Step3:
            if checkL("H") { advance(to: .typeH_Step4) }
        case .typeH_Step4:
            if checkL("H") { advance(to: .typeH_Step5) }
            
        case .predictHelp_Start:
            if checkL("HELP") || checkR("HELP") { advance(to: .predictHelp_Step1) }
        case .predictHelp_Step1:
            advance(to: .predictHelp_Step2)
        case .predictHelp_Step2:
            if checkL("HELP") { advance(to: .predictHelp_Select) }
            
        case .predictHello_Start:
            advance(to: .predictHello_Step1)
        case .predictHello_Step1:
            advance(to: .predictHello_Step2)
        case .predictHello_Step2:
            if checkR("HELLO") { advance(to: .predictHello_Select) }
            
        case .speak_Start:
            if checkR("Speak") { advance(to: .speak_Select) }
            
        case .clear_Start:
            if checkR("Clear") || checkL("Clear") { advance(to: .clear_Step1) }
        case .clear_Step1:
            if checkR("Clear") { advance(to: .clear_Select) }
            
        default: break
        }
    }
    
    // Helpers curtos para verificar labels (case insensitive e contem)
    func checkL(_ s: String) -> Bool { vocabManager.leftLabel.uppercased().contains(s.uppercased()) }
    func checkR(_ s: String) -> Bool { vocabManager.rightLabel.uppercased().contains(s.uppercased()) }
    
    func checkMessage() {
        let msg = vocabManager.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        switch phase {
        case .typeH_Step5: if msg == "H" { advance(to: .predictHelp_Intro, delay: 0.5) }
        case .predictHelp_Select: if msg.contains("HELP") { advance(to: .undo_Intro, delay: 1.0) }
        case .undo_Action: if msg == "HEL" { advance(to: .predictHello_Intro, delay: 0.5) }
        case .predictHello_Select: if msg.contains("HELLO") { advance(to: .speak_Intro, delay: 1.0) }
        case .clear_Select: if msg.isEmpty { advance(to: .completed, delay: 0.5) }
        default: break
        }
    }
    
    func checkSpeech() {
        if vocabManager.isSpeaking && phase == .pain_Select {
            triggerSuccess()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                vocabManager.currentMessage = ""
                setPhase(.typeH_Intro)
            }
        }
        if vocabManager.isSpeaking && phase == .speak_Select {
            advance(to: .clear_Intro, delay: 2.0)
        }
    }
    
    func advance(to next: StoryPhase, delay: Double = 0.0) {
        triggerSuccess()
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { setPhase(next) }
    }
    
    func setPhase(_ p: StoryPhase) {
        withAnimation { phase = p; updateTexts() }
        
        // Auto-Avanço de Intros
        let autoDelay: Double = 4.5
        switch p {
        case .pain_Intro: DispatchQueue.main.asyncAfter(deadline: .now() + autoDelay) { setPhase(.pain_Start) }
        case .typeH_Intro: DispatchQueue.main.asyncAfter(deadline: .now() + autoDelay) { setPhase(.typeH_Start) }
        case .predictHelp_Intro: DispatchQueue.main.asyncAfter(deadline: .now() + autoDelay) { setPhase(.predictHelp_Start) }
        case .undo_Intro: DispatchQueue.main.asyncAfter(deadline: .now() + autoDelay) { setPhase(.undo_Action) }
        case .predictHello_Intro: DispatchQueue.main.asyncAfter(deadline: .now() + autoDelay) { setPhase(.predictHello_Start) }
        case .speak_Intro: DispatchQueue.main.asyncAfter(deadline: .now() + autoDelay) { setPhase(.speak_Start) }
        case .clear_Intro: DispatchQueue.main.asyncAfter(deadline: .now() + autoDelay) { setPhase(.clear_Start) }
        case .completed: DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { onTutorialComplete() }
        default: break
        }
    }
    
    func triggerSuccess() {
        withAnimation { isSuccessFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { withAnimation { isSuccessFeedback = false } }
    }
    
    // MARK: - Roteiro (Storytelling)
    func startStory() {
        vocabManager.currentMessage = ""
        setPhase(.intro)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { setPhase(.pain_Intro) }
    }
    
    func updateTexts() {
        switch phase {
        case .intro:
            title = "Welcome"; subtitle = "Let's find your voice."
            currentFocus = .none
            
        // --- PAIN ---
        case .pain_Intro:
            title = "Emergency"; subtitle = "Imagine you are in pain.\nYou need to speak NOW."
            currentFocus = .none
        case .pain_Start:
            title = "Quick Words"; subtitle = "Smile RIGHT to open menu."
            currentFocus = .rightButton
        case .pain_Nav:
            title = "Find 'Pain'"; subtitle = "Navigate with Right Smile."
            currentFocus = .rightButton
        case .pain_Select:
            title = "Speak It"; subtitle = "Left Smile to select and speak."
            currentFocus = .leftButton
            
        // --- H ---
        case .typeH_Intro:
            title = "Precision"; subtitle = "Now let's write exactly what you want.\nLet's write 'H'."
            currentFocus = .none
        case .typeH_Start:
            title = "Alphabet"; subtitle = "Left Smile to enter Letters."
            currentFocus = .leftButton
        case .typeH_Step1:
            title = "Group A-M"; subtitle = "It's on the Left."
            currentFocus = .leftButton
        case .typeH_Step2:
            title = "Group H-M"; subtitle = "Now it's on the Right."
            currentFocus = .rightButton
        case .typeH_Step3:
            title = "Narrow Down"; subtitle = "Left Smile."
            currentFocus = .leftButton
        case .typeH_Step4:
            title = "Almost There"; subtitle = "Left Smile."
            currentFocus = .leftButton
        case .typeH_Step5:
            title = "Type 'H'"; subtitle = "Left Smile to confirm."
            currentFocus = .leftButton
            
        // --- HELP ---
        case .predictHelp_Intro:
            title = "Prediction"; subtitle = "See 'Help' in the suggestions?\nJuru guesses for you."
            currentFocus = .suggestions
        case .predictHelp_Start:
            title = "Enter Suggestions"; subtitle = "Right Smile to access them."
            currentFocus = .rightButton
        case .predictHelp_Step1:
            title = "Navigate"; subtitle = "Left Smile."
            currentFocus = .leftButton
        case .predictHelp_Step2:
            title = "Navigate"; subtitle = "Left Smile."
            currentFocus = .leftButton
        case .predictHelp_Select:
            title = "Select 'Help'"; subtitle = "Left Smile to pick it."
            currentFocus = .leftButton
            
        // --- UNDO ---
        case .undo_Intro:
            title = "Mistake?"; subtitle = "Oops, we wanted 'Hello'.\nNo problem."
            currentFocus = .none
        case .undo_Action:
            title = "The Eraser"; subtitle = "Make a KISS face (Pucker)\nto delete the 'P'."
            currentFocus = .speak
            
        // --- HELLO ---
        case .predictHello_Intro:
            title = "Found 'Hello'"; subtitle = "Look! It's right there."
            currentFocus = .suggestions
        case .predictHello_Start:
            title = "Enter Suggestions"; subtitle = "Right Smile."
            currentFocus = .rightButton
        case .predictHello_Step1:
            title = "Navigate"; subtitle = "Left Smile."
            currentFocus = .leftButton
        case .predictHello_Step2:
            title = "Navigate"; subtitle = "Left Smile."
            currentFocus = .leftButton
        case .predictHello_Select:
            title = "Select 'Hello'"; subtitle = "Right Smile this time."
            currentFocus = .rightButton
            
        // --- SPEAK ---
        case .speak_Intro:
            title = "Your Voice"; subtitle = "The text is ready.\nLet's vocalize it."
            currentFocus = .none
        case .speak_Start:
            title = "Commands"; subtitle = "Right Smile for menu."
            currentFocus = .rightButton
        case .speak_Select:
            title = "Say It!"; subtitle = "Right Smile to Speak."
            currentFocus = .rightButton
            
        // --- CLEAR ---
        case .clear_Intro:
            title = "Clean Up"; subtitle = "Ready for the next sentence?\nLet's clear."
            currentFocus = .none
        case .clear_Start:
            title = "Edit Menu"; subtitle = "Right Smile."
            currentFocus = .rightButton
        case .clear_Step1:
            title = "Find 'Clear'"; subtitle = "Left Smile."
            currentFocus = .leftButton
        case .clear_Select:
            title = "Clear All"; subtitle = "Right Smile."
            currentFocus = .rightButton
            
        case .completed:
            title = "You did it!"; subtitle = "You are ready."; currentFocus = .none
        }
    }
    
    // Propriedade Computada para mostrar ou esconder a pílula de ação
    var shouldShowAction: Bool {
        if currentFocus == .none { return false }
        switch phase {
        case .intro, .pain_Intro, .typeH_Intro, .predictHelp_Intro, .undo_Intro, .predictHello_Intro, .speak_Intro, .clear_Intro, .completed:
            return false
        default:
            return true
        }
    }
    
    // Helpers Visuais
    var iconForPhase: String {
        switch phase {
        case .intro, .pain_Intro, .typeH_Intro, .predictHelp_Intro, .undo_Intro, .predictHello_Intro, .speak_Intro, .clear_Intro, .completed:
            return "hand.wave.fill"
        case .pain_Start, .pain_Nav, .pain_Select: return "bolt.fill"
        case .typeH_Start, .typeH_Step1, .typeH_Step2, .typeH_Step3, .typeH_Step4, .typeH_Step5: return "keyboard"
        case .undo_Action: return "arrow.uturn.backward"
        case .speak_Select: return "waveform"
        case .clear_Select: return "trash.fill"
        default: return "sparkles"
        }
    }
    
    var actionIcon: String {
        if currentFocus == .leftButton { return "arrow.left" }
        if currentFocus == .rightButton { return "arrow.right" }
        if currentFocus == .speak { return "mouth" }
        return "face.smiling"
    }
    
    var actionText: String {
        if currentFocus == .leftButton { return "Left Smile" }
        if currentFocus == .rightButton { return "Right Smile" }
        if currentFocus == .speak { return "Pucker (Kiss)" }
        return "Look Here"
    }
}
