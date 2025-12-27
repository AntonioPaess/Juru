//
//  Trie.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 24/12/25.
//

import Foundation

class Trie {
    private let root: TrieNode
    
    init() {
        root = TrieNode()
    }
    
    func insert(_ word: String) {
        guard !word.isEmpty else { return }
        var currentNode = root
        let characteres = Array(word.lowercased())
        for character in characteres {
            currentNode = currentNode.add(child: character)
        }
        currentNode.isTerminating = true
    }
}
