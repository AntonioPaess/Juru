//
//  VocabularyManager.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
class VocabularyManager {
    // MARK: - Dependencies
    // Mantemos referência forte pois é injetado
    var faceManager: FaceTrackingManager
    private var trie = Trie()
    
    // MARK: - State
    var currentMessage: String = ""
    var suggestions: [String] = []
    
    // Navegação
    private var currentBranch: [String] = []
    private var branchHistory: [[String]] = []
    
    // UI Labels
    var leftLabel: String = ""
    var rightLabel: String = ""
    
    // Estado Lógico
    var isSelectingWord: Bool = false
    private var selectionTask: Task<Void, Never>?
    
    // Fonte de Dados (Imutáveis)
    let vowels = ["A", "E", "I", "O", "U"]
    let consonants = ["B", "C", "D", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "V", "W", "X", "Y", "Z"]
    let actions = ["Space", "Suggestions"]
    
    init(faceManager: FaceTrackingManager) {
        self.faceManager = faceManager
        setupDictionary()
        resetToRoot()
    }
    
    private func setupDictionary() {
        // Dicionário inicial (Poderia vir de um arquivo JSON no futuro)
        let initialWords = ["love", "now", "here", "ball", "home", "food", "day", "hello", "help", "yes", "no", "water", "please", "thanks"]
        for word in initialWords { trie.insert(word) }
    }
    
    // Loop Principal chamado pela View
    func update() {
        // Se já existe um timer rodando, verifica se o gesto parou para cancelar
        if selectionTask != nil {
            if !isGestureActive() { cancelTimer() }
            return
        }
        
        // Verifica os gatilhos calibrados
        if faceManager.isTriggeringLeft { startTimer(for: .selectLeft) }
        else if faceManager.isTriggeringRight { startTimer(for: .selectRight) }
        else if faceManager.isTriggeringBack { startTimer(for: .backOrDelete) }
    }
    
    private func isGestureActive() -> Bool {
        return faceManager.isTriggeringLeft || faceManager.isTriggeringRight || faceManager.isTriggeringBack
    }
    
    // MARK: - Timer / Debounce Logic
    private enum ActionType { case selectLeft, selectRight, backOrDelete }
    
    private func startTimer(for action: ActionType) {
        selectionTask = Task {
            // Tempo de "hold" para confirmar a seleção (0.4s)
            try? await Task.sleep(for: .seconds(0.4))
            if !Task.isCancelled {
                self.execute(action)
                self.selectionTask = nil
            }
        }
    }
    
    private func cancelTimer() {
        selectionTask?.cancel()
        selectionTask = nil
    }
    
    // MARK: - Execution Logic
    private func execute(_ action: ActionType) {
        switch action {
        case .selectLeft:  handleSelection(isLeft: true)
        case .selectRight: handleSelection(isLeft: false)
        case .backOrDelete: handleBack()
        }
    }
    
    // ... (O restante dos métodos handleSelection, processGroup, split, etc. mantêm-se iguais pois são lógica pura de navegação) ...
    // Estou omitindo aqui para economizar espaço, mas mantenha a lógica de Árvore Binária que já fizemos.
    // Certifique-se de que `handleBack` e `addCharacter` estejam lá.
    
    private func handleSelection(isLeft: Bool) {
        if currentBranch.isEmpty {
            // Salva histórico (Raiz)
            addToHistory([])
            isSelectingWord = false
            if isLeft { startBranch(vowels + consonants) }
            else { startBranch(actions) }
            return
        }
        
        let (left, right) = split(currentBranch)
        let chosen = isLeft ? left : right
        
        if chosen.count > 1 { addToHistory(currentBranch) }
        processGroup(chosen)
    }
    
    private func processGroup(_ group: [String]) {
        if group.count == 1 {
            let item = group.first!
            if item == "Suggestions" {
                if !suggestions.isEmpty {
                    isSelectingWord = true
                    addToHistory(currentBranch)
                    startBranch(suggestions)
                }
            } else if item == "Space" { addSpace() }
            else { isSelectingWord ? addWord(item) : addCharacter(item) }
        } else {
            startBranch(group)
        }
    }
    
    // Helpers de Navegação
    private func startBranch(_ items: [String]) { currentBranch = items; updateLabels() }
    
    private func split(_ items: [String]) -> ([String], [String]) {
        let mid = (items.count + 1) / 2
        return (Array(items[0..<mid]), Array(items[mid..<items.count]))
    }
    
    private func updateLabels() {
        if currentBranch.isEmpty { resetToRoot(); return }
        let (left, right) = split(currentBranch)
        leftLabel = formatLabel(left)
        rightLabel = formatLabel(right)
    }
    
    private func formatLabel(_ items: [String]) -> String {
        if items.count == 1 { return items.first! }
        if items.count <= 3 { return items.joined(separator: " ") }
        if isSelectingWord { return "\(items.first!) ... \(items.last!)" }
        return "\(items.first!) - \(items.last!)"
    }
    
    private func handleBack() {
        if !branchHistory.isEmpty {
            let prev = branchHistory.removeLast()
            if prev.isEmpty { resetToRoot() } else { startBranch(prev) }
        } else { deleteLast() }
    }
    
    private func addToHistory(_ state: [String]) { branchHistory.append(state) }
    
    private func resetToRoot() {
        currentBranch = []; branchHistory = []; isSelectingWord = false
        leftLabel = "Letters"; rightLabel = "Actions"
    }
    
    // Edição de Texto
    private func addCharacter(_ char: String) {
        let val = (currentMessage.isEmpty || currentMessage.hasSuffix(". ")) ? char.uppercased() : char.lowercased()
        currentMessage.append(val); updateSuggestions(); resetToRoot()
    }
    
    private func addWord(_ word: String) {
        // Lógica para substituir a palavra parcial se necessário
        let words = currentMessage.split(separator: " ")
        if !words.isEmpty && !currentMessage.hasSuffix(" ") {
            let partialLen = words.last?.count ?? 0
            currentMessage.removeLast(partialLen)
        }
        let val = (currentMessage.isEmpty || currentMessage.hasSuffix(". ")) ? word.capitalized : word.lowercased()
        currentMessage.append(val + " "); suggestions = []; resetToRoot()
    }
    
    private func addSpace() { currentMessage.append(" "); updateSuggestions(); resetToRoot() }
    
    private func deleteLast() {
        if !currentMessage.isEmpty { currentMessage.removeLast(); updateSuggestions() }
        resetToRoot()
    }
    
    private func updateSuggestions() {
        let last = currentMessage.split(separator: " ").last.map(String.init) ?? ""
        suggestions = last.isEmpty ? [] : trie.findWords(startingWith: last)
    }
}
