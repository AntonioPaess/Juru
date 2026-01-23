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
        
        case pain_Intro
        case pain_Switch    // Levantar sobrancelha para trocar o foco
        case pain_Select    // Fazer bico para confirmar
        
        case typeH_Intro
        case typeH_FocusLeft
        case typeH_SelectLeft
        case typeH_FocusRight
        case typeH_SelectRight
        case typeH_Confirm
        
        case undo_Intro
        case undo_Action // Long Press
        
        case completed
    }
    
    @State private var phase: StoryPhase = .intro
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var isSuccessFeedback: Bool = false
    
    // Controle para evitar múltiplos disparos
    @State private var isTransitioning: Bool = false
    
    @Environment(\.horizontalSizeClass) var sizeClass
    var isPad: Bool { sizeClass == .regular }
    
    var body: some View {
        VStack {
            if isPad {
                instructionCard.padding(.top, 40)
                Spacer()
            } else {
                Spacer()
                instructionCard.padding(.bottom, 130)
            }
        }
        .padding(.horizontal, isPad ? 100 : 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        .onAppear { startStory() }
        // Monitora mudanças no foco (Sobrancelha)
        .onChange(of: faceManager.currentFocusState) { checkNavigation() }
        // Monitora mudanças no texto (Seleção via Bico)
        .onChange(of: vocabManager.currentMessage) { checkMessage() }
        // Monitora ação de desfazer
        .onChange(of: faceManager.isBackingOut) { checkUndo() }
    }
    
    var instructionCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
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
    
    // Lógica de Navegação (Sobrancelha)
    func checkNavigation() {
        guard !isTransitioning else { return }
        
        switch phase {
        case .pain_Switch:
            // Objetivo: Ir para a Direita
            if faceManager.currentFocusState == 2 {
                advance(to: .pain_Select)
            }
            
        case .typeH_FocusLeft:
            // Objetivo: Ir para a Esquerda
            if faceManager.currentFocusState == 1 {
                advance(to: .typeH_SelectLeft)
            }
            
        case .typeH_FocusRight:
            // Objetivo: Ir para a Direita (H-M)
            if faceManager.currentFocusState == 2 {
                advance(to: .typeH_SelectRight)
            }
            
        default: break
        }
    }
    
    // Lógica de Mensagem (Bico/Seleção)
    func checkMessage() {
        guard !isTransitioning else { return }
        let msg = vocabManager.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        switch phase {
        case .pain_Select:
             // Espera que QUALQUER coisa seja selecionada nos Quick Words
             if !msg.isEmpty {
                 // Limpa a mensagem para a próxima etapa não pegar lixo
                 vocabManager.currentMessage = ""
                 advance(to: .typeH_Intro, delay: 1.5)
             }
             
        case .typeH_SelectLeft:
             // Verificamos se o Label mudou, indicando que entrou no grupo
             if !vocabManager.leftLabel.contains("Letters") {
                 advance(to: .typeH_FocusRight)
             }
             
        case .typeH_SelectRight:
             // Verificamos se entrou no subgrupo (H-M)
             // Assumindo que a navegação funcionou, apenas avançamos
             advance(to: .typeH_Confirm)
             
        case .typeH_Confirm:
             // Verifica se a letra H foi digitada
             if msg.contains("H") {
                 advance(to: .undo_Intro, delay: 1.0)
             }
             
        default: break
        }
    }
    
    func checkUndo() {
        guard !isTransitioning else { return }
        
        if phase == .undo_Action && faceManager.isBackingOut {
            triggerSuccess()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onTutorialComplete()
            }
        }
    }
    
    func advance(to next: StoryPhase, delay: Double = 0.0) {
        // Bloqueia múltiplas chamadas
        isTransitioning = true
        
        triggerSuccess()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            setPhase(next)
            // Libera transições após a mudança de fase ter assentado
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isTransitioning = false
            }
        }
    }
    
    func setPhase(_ p: StoryPhase) {
        withAnimation { phase = p; updateTexts() }
        
        // Auto-avanço para fases apenas informativas
        let autoDelay: Double = 4.5
        switch p {
        case .pain_Intro:
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDelay) {
                if phase == .pain_Intro { setPhase(.pain_Switch) }
            }
        case .typeH_Intro:
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDelay) {
                if phase == .typeH_Intro { setPhase(.typeH_FocusLeft) }
            }
        case .undo_Intro:
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDelay) {
                if phase == .undo_Intro { setPhase(.undo_Action) }
            }
        default: break
        }
    }
    
    func triggerSuccess() {
        withAnimation { isSuccessFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { withAnimation { isSuccessFeedback = false } }
    }
    
    func startStory() {
        vocabManager.currentMessage = ""
        setPhase(.intro)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { setPhase(.pain_Intro) }
    }
    
    func updateTexts() {
        switch phase {
        case .intro:
            title = "Welcome"; subtitle = "Let's learn the Brow-Scanner."
            currentFocus = .none
            
        // --- PAIN ---
        case .pain_Intro:
            title = "Navigation"; subtitle = "Raise your eyebrows to move the cursor."
            currentFocus = .none
        case .pain_Switch:
            title = "Move Focus"; subtitle = "Raise Brows until RIGHT button glows."
            currentFocus = .rightButton
        case .pain_Select:
            title = "Select It"; subtitle = "Release Pucker to select 'Quick Words'."
            currentFocus = .rightButton
            
        // --- TYPE H ---
        case .typeH_Intro:
            title = "Typing"; subtitle = "Let's type the letter 'H'."
            currentFocus = .none
        case .typeH_FocusLeft:
            title = "Find Letters"; subtitle = "Raise Brows to highlight LEFT."
            currentFocus = .leftButton
        case .typeH_SelectLeft:
            title = "Open Group"; subtitle = "Release Pucker to open A-Z."
            currentFocus = .leftButton
        case .typeH_FocusRight:
            title = "Narrow Down"; subtitle = "Raise Brows to highlight RIGHT."
            currentFocus = .rightButton
        case .typeH_SelectRight:
            title = "Select Group"; subtitle = "Release Pucker to open group."
            currentFocus = .rightButton
        case .typeH_Confirm:
            title = "Finish H"; subtitle = "Find 'H' and Select it.";
            currentFocus = .leftButton
            
        // --- UNDO ---
        case .undo_Intro:
            title = "Mistakes happen"; subtitle = "To go back, we use time."
            currentFocus = .none
        case .undo_Action:
            title = "Long Press"; subtitle = "HOLD Pucker until RED, then Release."
            currentFocus = .none
            
        case .completed:
            title = "You did it!"; subtitle = "You are ready."; currentFocus = .none
        }
    }
    
    var shouldShowAction: Bool {
        if currentFocus == .none { return false }
        switch phase {
        case .intro, .pain_Intro, .typeH_Intro, .undo_Intro, .completed: return false
        default: return true
        }
    }
    
    var iconForPhase: String {
        switch phase {
        case .undo_Action: return "arrow.uturn.backward"
        default: return "face.smiling"
        }
    }
    
    var actionIcon: String {
        if phase == .pain_Switch || phase == .typeH_FocusLeft || phase == .typeH_FocusRight { return "eyebrow" }
        if phase == .undo_Action { return "clock.arrow.circlepath" }
        return "mouth"
    }
    
    var actionText: String {
        if phase == .pain_Switch || phase == .typeH_FocusLeft || phase == .typeH_FocusRight { return "Raise Brows" }
        if phase == .undo_Action { return "Hold & Release" }
        return "Pucker & Release"
    }
}
