//
//  TrieNode.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 24/12/25.
//

import Foundation

import Foundation

class TrieNode {
    var value: Character?
    var children: [Character: TrieNode] = [:]
    var isTerminating: Bool = false
    
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
