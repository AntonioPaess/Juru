//
//  TrieNode.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 24/12/25.
//

import Foundation

class TrieNode {
    var value: Character?
    var children: [Character: TrieNode] = [:]
    var isTerminating: Bool = false
    weak var parent: TrieNode?
    
    init(
        value: Character? = nil,
        parent: TrieNode? = nil
    ) {
        self.value = value
        self.parent = parent
    }
    
    // MARK: Add or Create Node
    
    func add(child: Character) -> TrieNode {
        if let node = children[child] {
            return node
        } else {
            let node = TrieNode(value: child, parent: self)
            children[child] = node
            return node
        }
    }
}
