//
//  VocabularyManager.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class VocabularyManager {
    // MARK: - Dependencies
    var faceManager: FaceTrackingManager
    private var trie = Trie()
    
    // MARK: - State
    var currentMessage: String = ""
    var suggestions: [String] = []
    
    // Árvore de Navegação Atual
    private var currentBranch: [String] = []
    
    // ✅ NOVO: Histórico para o botão "Voltar" funcionar nível por nível
    private var branchHistory: [[String]] = []
    
    // O que mostrar nas bolas
    var leftLabel: String = ""
    var rightLabel: String = ""
    
    // Estado para saber se estamos escolhendo letras ou palavras
    var isSelectingWord: Bool = false
    
    // Timer
    private var selectionTask: Task<Void, Never>?
    
    // MARK: - Data Source
    let vowels = ["A", "E", "I", "O", "U"]
    let consonants = ["B", "C", "D", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "V", "W", "X", "Y", "Z"]
    
    // ✅ "Delete" removido, pois o bico já faz isso
    let actions = ["Space", "Suggestions"]
    
    // MARK: - Init
    init(faceManager: FaceTrackingManager) {
        self.faceManager = faceManager
        setupDictionary()
        resetToRoot()
    }
    
    private func setupDictionary() {
        let initialWords = ["love", "now", "here", "ball", "home", "food", "day", "hello", "help", "yes", "no", "water", "please", "thanks"]
        for word in initialWords { trie.insert(word) }
    }
    
    // MARK: - Logic Loop
    func update() {
        if selectionTask != nil {
            if !isGestureActive() { cancelTimer() }
            return
        }
        
        if faceManager.smileLeft > 0.5 { startTimer(for: .selectLeft) }
        else if faceManager.smileRight > 0.5 { startTimer(for: .selectRight) }
        else if faceManager.mouthPucker > 0.5 { startTimer(for: .backOrDelete) }
    }
    
    private func isGestureActive() -> Bool {
        return faceManager.smileLeft > 0.5 || faceManager.smileRight > 0.5 || faceManager.mouthPucker > 0.5
    }
    
    // MARK: - Timer Logic
    private enum ActionType { case selectLeft, selectRight, backOrDelete }
    
    private func startTimer(for action: ActionType) {
        selectionTask = Task {
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
    
    // MARK: - EXECUTION
    
    private func execute(_ action: ActionType) {
        switch action {
        case .selectLeft:  handleSelection(isLeft: true)
        case .selectRight: handleSelection(isLeft: false)
        case .backOrDelete: handleBack()
        }
    }
    
    private func handleSelection(isLeft: Bool) {
        if currentBranch.isEmpty {
            if isLeft {
                isSelectingWord = false
                addToHistory([])
                startBranch(vowels + consonants)
            } else {
                isSelectingWord = false
                addToHistory([])
                startBranch(actions)
            }
            return
        }
        
        let (leftGroup, rightGroup) = split(currentBranch)
        let chosenGroup = isLeft ? leftGroup : rightGroup

        if chosenGroup.count > 1 {
            addToHistory(currentBranch)
        }
        
        processGroup(chosenGroup)
    }
    
    private func processGroup(_ group: [String]) {
        if group.count == 1 {
            let item = group.first!
            
            if item == "Suggestions" {
                if !suggestions.isEmpty {
                    isSelectingWord = true
                    addToHistory(currentBranch)
                    startBranch(suggestions)
                } else {
                }
            } else if item == "Space" {
                addSpace()
            } else {
                if isSelectingWord { addWord(item) }
                else { addCharacter(item) }
            }
        } else {
            currentBranch = group
            updateLabels()
        }
    }
    
    private func split(_ items: [String]) -> ([String], [String]) {
        let mid = (items.count + 1) / 2
        return (Array(items[0..<mid]), Array(items[mid..<items.count]))
    }
    
    private func startBranch(_ items: [String]) {
        currentBranch = items
        updateLabels()
    }
    
    private func updateLabels() {
        if currentBranch.isEmpty {
            resetToRoot()
            return
        }
        let (left, right) = split(currentBranch)
        leftLabel = formatLabel(left)
        rightLabel = formatLabel(right)
    }
    
    private func formatLabel(_ items: [String]) -> String {
        if items.count == 1 { return items.first! }
        if items.count <= 3 { return items.joined(separator: " ") }
        
        if isSelectingWord {
            return "\(items.first!) ... \(items.last!)"
        }
        return "\(items.first!) - \(items.last!)"
    }
    
    // MARK: - Back Logic (O Pulo do Gato) 🐈
    
    private func addToHistory(_ state: [String]) {
        branchHistory.append(state)
    }
    
    private func handleBack() {
        if !branchHistory.isEmpty {
            let previousState = branchHistory.removeLast()
            
            if previousState.isEmpty {
                resetToRoot()
            } else {
                startBranch(previousState)
            }
        }
        else {
            deleteLast()
        }
    }
    
    // MARK: - Typing Logic
    
    private func addCharacter(_ char: String) {
        let charToAdd: String
        if currentMessage.isEmpty || currentMessage.hasSuffix(". ") {
            charToAdd = char.uppercased()
        } else {
            charToAdd = char.lowercased()
        }
        
        currentMessage.append(charToAdd)
        updateSuggestions()
        resetToRoot()
    }
    
    private func addWord(_ word: String) {
        let words = currentMessage.split(separator: " ")
        if !words.isEmpty && !currentMessage.hasSuffix(" ") {
             let partialLength = words.last?.count ?? 0
             currentMessage.removeLast(partialLength)
        }
        
        let wordToAdd = (currentMessage.isEmpty || currentMessage.hasSuffix(". ")) ? word.capitalized : word.lowercased()
        
        currentMessage.append(wordToAdd + " ")
        suggestions = []
        resetToRoot()
    }
    
    private func addSpace() {
        currentMessage.append(" ")
        updateSuggestions()
        resetToRoot()
    }
    
    private func deleteLast() {
        if !currentMessage.isEmpty {
            currentMessage.removeLast()
            updateSuggestions()
        }
        resetToRoot()
    }
    
    private func resetToRoot() {
        currentBranch = []
        branchHistory = []
        isSelectingWord = false
        leftLabel = "Letters"
        rightLabel = "Actions"
    }
    
    private func updateSuggestions() {
        let lastWord = currentMessage.split(separator: " ").last.map(String.init) ?? ""
        if !lastWord.isEmpty {
            suggestions = trie.findWords(startingWith: lastWord)
        } else {
            suggestions = []
        }
    }
}
