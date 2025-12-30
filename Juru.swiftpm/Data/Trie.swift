//
//  Trie.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 24/12/25.
//

import Foundation

// MARK: - Fix Swift 6 Concurrency
// final + @unchecked Sendable permite transferir a instância da Task de background
// para a Main Thread sem erros de compilação.
final class Trie: @unchecked Sendable {
    private let root: TrieNode
    
    init() {
        root = TrieNode()
    }
    
    func insert(_ word: String, rank: Int) {
        guard !word.isEmpty else { return }
        var currentNode = root
        let characters = Array(word.lowercased())
        for character in characters {
            currentNode = currentNode.add(child: character)
        }
        currentNode.isTerminating = true
        
        // Mantém o melhor rank (menor número) se a palavra for reinserida
        if currentNode.rank == nil || rank < (currentNode.rank ?? Int.max) {
            currentNode.rank = rank
        }
    }
    
    func findWordsWithRank(startingWith prefix: String) -> [(text: String, rank: Int)] {
        var currentNode = root
        let characters = Array(prefix.lowercased())
        for character in characters {
            if let node = currentNode.children[character] {
                currentNode = node
            } else {
                return []
            }
        }
        return collectWords(from: currentNode, prefix: prefix.lowercased())
    }
}

extension Trie {
    private func collectWords(from node: TrieNode, prefix: String) -> [(text: String, rank: Int)] {
        var results = [(String, Int)]()
        
        if node.isTerminating, let rank = node.rank {
            results.append((prefix, rank))
        }
        
        for (char, childNode) in node.children {
            let newPrefix = prefix + String(char)
            let childResults = collectWords(from: childNode, prefix: newPrefix)
            results.append(contentsOf: childResults)
        }
        return results
    }
}
