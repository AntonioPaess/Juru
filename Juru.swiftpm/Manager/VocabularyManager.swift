//
//  VocabularyManager.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

import Foundation
import SwiftUI
import Observation
import AVFoundation

@MainActor
@Observable
class VocabularyManager {
    // MARK: - Dependencies
    var faceManager: FaceTrackingManager
    private var trie = Trie()
    let synthesizer = AVSpeechSynthesizer()
    var isDictionaryLoaded = false
    
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
    
    // Fonte de Dados
    let vowels = ["A", "E", "I", "O", "U"]
    let consonants = ["B", "C", "D", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "V", "W", "X", "Y", "Z"]
    let actions = ["Space", "Suggestions"]
    
    init(faceManager: FaceTrackingManager) {
        self.faceManager = faceManager
        resetToRoot()
        // Inicia carregamento em background
        Task {
            await loadDictionary()
        }
    }
    
    private func loadDictionary() async {
        // Carregamento pesado fora da Main Thread
        let loadedTrie = await Task.detached(priority: .userInitiated) { () -> Trie in
            let newTrie = Trie()
            
            // Tenta carregar do JSON
            if let url = Bundle.main.url(forResource: "WordsData", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let words = try? JSONDecoder().decode([String].self, from: data) {
                
                // Insere com rank (índice 0 = mais frequente)
                for (index, word) in words.enumerated() {
                    newTrie.insert(word, rank: index)
                }
                print("Dicionário carregado com \(words.count) palavras.")
            } else {
                // Fallback se o JSON falhar
                let initialWords = ["love", "now", "here", "ball", "home", "food", "day", "hello", "help", "yes", "no", "water", "please", "thanks"]
                for (index, word) in initialWords.enumerated() {
                    newTrie.insert(word, rank: index)
                }
                print("Usando dicionário de fallback.")
            }
            return newTrie
        }.value
        
        // Atualiza na Main Thread
        self.trie = loadedTrie
        self.isDictionaryLoaded = true
    }
    
    // Loop Principal
    func update() {
        if selectionTask != nil {
            if !isGestureActive() { cancelTimer() }
            return
        }
        
        if faceManager.isTriggeringLeft { startTimer(for: .selectLeft) }
        else if faceManager.isTriggeringRight { startTimer(for: .selectRight) }
        else if faceManager.isTriggeringBack { startTimer(for: .backOrDelete) }
    }
    
    private func isGestureActive() -> Bool {
        return faceManager.isTriggeringLeft || faceManager.isTriggeringRight || faceManager.isTriggeringBack
    }
    
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

    func speakCurrentMessage() {
        let utterance = AVSpeechUtterance(string: currentMessage)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US") // Ou use o locale atual
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
    
    private func execute(_ action: ActionType) {
        switch action {
        case .selectLeft:  handleSelection(isLeft: true)
        case .selectRight: handleSelection(isLeft: false)
        case .backOrDelete: handleBack()
        }
    }
    
    private func handleSelection(isLeft: Bool) {
        if currentBranch.isEmpty {
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
    
    private func addCharacter(_ char: String) {
        let val = (currentMessage.isEmpty || currentMessage.hasSuffix(". ")) ? char.uppercased() : char.lowercased()
        currentMessage.append(val); updateSuggestions(); resetToRoot()
    }
    
    private func addWord(_ word: String) {
        let words = currentMessage.split(separator: " ")
        if !words.isEmpty && !currentMessage.hasSuffix(" ") {
            let partialLen = words.last?.count ?? 0
            currentMessage.removeLast(partialLen)
        }
        // Capitaliza se for início de frase
        let val = (currentMessage.isEmpty || currentMessage.hasSuffix(". ")) ? word.capitalized : word.lowercased()
        currentMessage.append(val + " "); suggestions = []; resetToRoot()
    }
    
    private func addSpace() { currentMessage.append(" "); updateSuggestions(); resetToRoot() }
    
    private func deleteLast() {
        if !currentMessage.isEmpty { currentMessage.removeLast(); updateSuggestions() }
        resetToRoot()
    }
    
    // ATUALIZADO: Busca otimizada (Top 4)
    private func updateSuggestions() {
        // Pega a última palavra sendo digitada
        let lastWord = currentMessage.split(separator: " ").last.map(String.init) ?? ""
        
        // Se a última letra digitada foi espaço, não sugere nada (início de nova palavra)
        if currentMessage.hasSuffix(" ") || lastWord.isEmpty {
            suggestions = []
            return
        }
        
        // Busca na Trie com Ranks
        let results = trie.findWordsWithRank(startingWith: lastWord)
        
        // Ordena por Rank (menor é melhor) e pega as 4 primeiras
        // Filtra para não sugerir exatamente o que já foi digitado se for a única opção, mas mantém para autocompletar
        let topSuggestions = results
            .sorted { $0.rank < $1.rank }
            .prefix(4)
            .map { $0.text }
        
        suggestions = Array(topSuggestions)
    }
}
