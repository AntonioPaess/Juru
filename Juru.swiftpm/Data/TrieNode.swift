//
//  TrieNode.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 24/12/25.
//

import Foundation

// MARK: - Fix Swift 6 Concurrency
// Marcamos como @unchecked Sendable porque a classe é mutável,
// mas garantimos no VocabularyManager que ela é construída em isolamento
// e depois transferida para o MainActor, onde reside exclusivamente.
final class TrieNode: @unchecked Sendable {
    var value: Character?
    var children: [Character: TrieNode] = [:]
    var isTerminating: Bool = false
    var rank: Int?
    
    init(value: Character? = nil) {
        self.value = value
    }
    
    func add(child: Character) -> TrieNode {
        if let node = children[child] {
            return node
        } else {
            let node = TrieNode(value: child)
            children[child] = node
            return node
        }
    }
}
