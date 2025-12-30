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

struct NeonBall: View {
    let text: String
    let color: Color
    let positionLabel: String
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: 3)
                .shadow(color: color.opacity(0.8), radius: 15)
                .background(Color.black.opacity(0.01))
            
            Text(text)
                .font(.system(size: fontSizeFor(text, size), weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(10)
                .shadow(radius: 5)
                .minimumScaleFactor(0.4)
            
            VStack {
                Spacer()
                HStack(spacing: 4) {
                    if positionLabel == "LEFT" { Image(systemName: "arrow.left") }
                    Text(positionLabel)
                        .font(.system(size: size * 0.08, weight: .black))
                    
                    if positionLabel == "RIGHT" { Image(systemName: "arrow.right") }
                }
                .foregroundStyle(color)
                .padding(.bottom, size * 0.15)
            }
        }
        .frame(width: size, height: size)
    }
    
    func fontSizeFor(_ text: String, _ ballSize: CGFloat) -> CGFloat {
        if text.count <= 2 { return ballSize * 0.35 }
        if text.count <= 10 { return ballSize * 0.15 }
        return ballSize * 0.10
    }
}

#Preview {
    let faceManager = FaceTrackingManager()
    let vocabManager = VocabularyManager(faceManager: faceManager)
    ZStack {
        Color.black.ignoresSafeArea()
        KeyboardView(vocabManager: vocabManager)
    }
}
