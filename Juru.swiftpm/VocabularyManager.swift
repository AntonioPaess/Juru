//
//  VocabularyManager.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

import Foundation
import SwiftUI

enum NavigationState {
    case groups
    case vowels
    case consonantsPart1
}

@MainActor
@Observable
class VocabularyManager {
    // MARK: - Dependencies
    var faceManager: FaceTrackingManager
    private var trie = Trie()
    
    // MARK: - Published State
    var currentMessage: String = ""
    var suggestions: [String] = []
    var navigationState: NavigationState = .groups
    private var selectionTask: Task<Void, Never>?
    
    // MARK: - Init
    init(faceManager: FaceTrackingManager) {
        self.faceManager = faceManager
        setupDictionary()
    }
    
    // MARK: - Setup
    private func setupDictionary() {
        let initialWords = [
            "love",
            "now",
            "here",
            "ball",
            "home",
            "food",
            "day",
            "hello",
            "help",
            "yes",
            "no"
        ]
        
        for word in initialWords {
            trie.insert(word)
        }
    }
    
    // MARK: - Logic (Decision Loop)
    
    func update() {
        if selectionTask != nil {
            if !isGestureActive() {
                cancelTimer()
            }
            return
        }
        
        if faceManager.smileRight > 0.5 {
            startTimer(for: .select)
        } else if faceManager.smileLeft > 0.5 {
            startTimer(for: .navigate)
        } else if faceManager.mouthPucker > 0.5 {
            startTimer(for: .delete)
        }
    }
    
    private func isGestureActive() -> Bool {
        return faceManager.smileRight > 0.5 ||
               faceManager.smileLeft > 0.5 ||
               faceManager.mouthPucker > 0.5
    }
    
    // MARK: - Timer Logic
    
    private enum ActionType {
        case select, navigate, delete
    }
    
    private func startTimer(for action: ActionType) {
        selectionTask = Task {
            try? await Task.sleep(for: .seconds(0.5))
            
            if !Task.isCancelled {
                self.execute(action)
                self.selectionTask = nil
            }
        }
    }
    
    private func cancelTimer() {
        selectionTask?.cancel()
        selectionTask = nil
        print("Gesture cancelled")
    }
    
    // MARK: - Execution
    
    private func execute(_ action: ActionType) {
        switch action {
        case .select:
            print("CONFIRMED: Select")
            handleSelection()
            
        case .navigate:
            print("CONFIRMED: Navigate/Next")
            handleNavigation()
            
        case .delete:
            print("CONFIRMED: Delete/Back")
            handleDelete()
        }
    }
    
    // MARK: - Actions Implementation
    
    private func handleSelection() {
        print("ACTION: Select")
    }
    
    private func handleNavigation() {
        print("ACTION: Navigate")
    }
    
    private func handleDelete() {
        print("ACTION: Delete")
    }
}
