//
//  KeyboardView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

import SwiftUI

struct KeyboardView: View {
    var vocabManager: VocabularyManager
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let ballSize = min(availableWidth * 0.4, 250)
            
            HStack(spacing: 0) {
                Spacer()
                // ✅ Usando NeonBall do UIComponents.swift
                NeonBall(
                    text: vocabManager.leftLabel,
                    color: .cyan,
                    positionLabel: "LEFT",
                    size: ballSize
                )
                Spacer()
                NeonBall(
                    text: vocabManager.rightLabel,
                    color: .pink,
                    positionLabel: "RIGHT",
                    size: ballSize
                )
                Spacer()
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(height: 300)
    }
}
