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
    // MARK: - Dependências
    var faceManager: FaceTrackingManager
    private var trie = Trie()
    var isDictionaryLoaded = false
    private let synthesizer = AVSpeechSynthesizer()
    
    // Configurações
    var isDarkMode: Bool = true
    
    // MARK: - Estado
    var currentMessage: String = ""
    var suggestions: [String] = []
    
    // Navegação
    var currentBranch: [String] = []
    private var branchHistory: [[String]] = []
    
    // Etiquetas UI
    var leftLabel: String = "Speller"
    var rightLabel: String = "Quick Words"
    
    // Estado Lógico
    var isSelectingWord: Bool = false
    private var selectionTask: Task<Void, Never>?
    
    // MARK: - DADOS ESTÁTICOS
    
    let alphabet = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    let quickPhrases = ["Yes", "No", "Pain", "Water"]
    let editingCommands = ["Space", "Speak"]
    
    // MARK: - Init & Setup
    init(faceManager: FaceTrackingManager) {
        self.faceManager = faceManager
        setupAudio()
        resetToRoot()
        Task { await loadDictionary() }
    }
    
    private func setupAudio() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    private func loadDictionary() async {
        let loadedTrie = await Task.detached(priority: .userInitiated) { () -> Trie in
            let newTrie = Trie()
            if let url = Bundle.main.url(forResource: "WordsData", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let words = try? JSONDecoder().decode([String].self, from: data) {
                for (index, word) in words.enumerated() { newTrie.insert(word, rank: index) }
            } else {
                ["hello", "thanks", "please", "water", "pain", "yes", "no"].enumerated().forEach { newTrie.insert($0.element, rank: $0.offset) }
            }
            return newTrie
        }.value
        self.trie = loadedTrie
        self.isDictionaryLoaded = true
    }
    
    // MARK: - Game Loop
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
    
    private func execute(_ action: ActionType) {
        switch action {
        case .selectLeft:  handleSelection(isLeft: true)
        case .selectRight: handleSelection(isLeft: false)
        case .backOrDelete: handleBack()
        }
    }
    
    // MARK: - Lógica Contextual
    private func handleSelection(isLeft: Bool) {
        if currentBranch.isEmpty {
            addToHistory([])
            if isLeft {
                isSelectingWord = false
                startBranch(alphabet)
            } else {
                let contextMenu = generateRightContextMenu()
                isSelectingWord = true
                startBranch(contextMenu)
            }
            return
        }
        
        let (left, right) = split(currentBranch)
        let chosen = isLeft ? left : right
        
        if chosen.count > 1 {
            addToHistory(currentBranch)
            startBranch(chosen)
        } else {
            if let item = chosen.first {
                executeLeafNode(item)
            }
        }
    }
    
    private func generateRightContextMenu() -> [String] {
        if currentMessage.isEmpty {
            return quickPhrases
        } else {
            var menu: [String] = []
            if suggestions.count > 0 { menu.append(suggestions[0]) }
            if suggestions.count > 1 { menu.append(suggestions[1]) }
            menu.append(contentsOf: editingCommands)
            return menu
        }
    }
    
    private func executeLeafNode(_ item: String) {
        switch item {
        case "Space":
            addSpace()
        case "Speak":
            speakCurrentMessage()
            suggestions = []
            resetToRoot()
        case "Clear":
            currentMessage = ""
            suggestions = []
            resetToRoot()
        case "Yes", "No", "Pain", "Water":
            speak(text: item)
            currentMessage = ""; resetToRoot()
        default:
            if isSelectingWord { addWord(item) }
            else { addCharacter(item) }
        }
    }
    
    // MARK: - Helpers de Navegação
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
        if items.contains("A") && items.contains("Z") { return "A - Z" }
        if items.count <= 3 { return items.joined(separator: "\n") }
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
        updateSuggestions()
        leftLabel = "A - Z"
        rightLabel = currentMessage.isEmpty ? "Quick Words" : (suggestions.isEmpty ? "Edit & Speak" : "Predict & Edit")
    }
    
    // MARK: - Manipulação de Texto
    private func addCharacter(_ char: String) {
        let val = (currentMessage.isEmpty || currentMessage.hasSuffix(". ")) ? char.uppercased() : char.lowercased()
        currentMessage.append(val)
        updateSuggestions()
        resetToRoot()
    }
    
    // CORREÇÃO AQUI: Substituição inteligente
    private func addWord(_ word: String) {
        // Se a mensagem não está vazia e não termina com espaço,
        // significa que estamos no meio de uma palavra (ex: "Hel").
        // Removemos essa parte parcial antes de adicionar a palavra completa.
        if !currentMessage.isEmpty && !currentMessage.hasSuffix(" ") {
            if let lastSpaceIndex = currentMessage.lastIndex(of: " ") {
                // Remove tudo depois do último espaço
                currentMessage = String(currentMessage[...lastSpaceIndex])
            } else {
                // Se não tem espaço, é a primeira palavra sendo digitada. Limpa tudo.
                currentMessage = ""
            }
        }
        
        // Verifica se precisa capitalizar (início de frase)
        let shouldCapitalize = currentMessage.isEmpty || currentMessage.hasSuffix(". ")
        let val = shouldCapitalize ? word.capitalized : word.lowercased()
        
        currentMessage.append(val + " ")
        suggestions = []
        resetToRoot()
    }
    
    private func addSpace() { currentMessage.append(" "); updateSuggestions(); resetToRoot() }
    
    private func deleteLast() {
        if !currentMessage.isEmpty { currentMessage.removeLast(); updateSuggestions() }
        resetToRoot()
    }
    
    private func updateSuggestions() {
        let lastWord = currentMessage.split(separator: " ").last.map(String.init) ?? ""
        if currentMessage.hasSuffix(" ") || lastWord.isEmpty {
            suggestions = []; return
        }
        let results = trie.findWordsWithRank(startingWith: lastWord)
        let top = results.sorted { $0.rank < $1.rank }.prefix(2).map { $0.text }
        suggestions = Array(top)
    }
    
    func speakCurrentMessage() { speak(text: currentMessage.isEmpty ? "No text" : currentMessage) }
    
    func speak(text: String) {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}
