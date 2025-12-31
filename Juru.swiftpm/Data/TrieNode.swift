//
//  TrieNode.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 24/12/25.
//

import Foundation

// MARK: - Fix Swift 6 Concurrency
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
