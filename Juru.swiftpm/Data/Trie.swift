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
    
    func findWords(startingWith prefix: String) -> [String] {
        var currentNode = root
        let charactares = Array(prefix.lowercased())
        for character in charactares {
            if let node = currentNode.children[character] {
                currentNode = node
            } else {
                return []
            }
        }
        return collectWords(from: currentNode, prefix: prefix)
    }
}

extension Trie {
    private func collectWords(from node: TrieNode, prefix: String) -> [String] {
        var wordsArray = Array<String>()
        if node.isTerminating {
            wordsArray.append(prefix)
        }
        for (char, childNode) in node.children {
            let newPrefix = prefix + String(char)
            let childWord = collectWords(from: childNode, prefix: newPrefix)
            wordsArray.append(contentsOf: childWord)
        }
        return wordsArray
    }
}
