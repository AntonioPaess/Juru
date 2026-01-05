//
//  JuruAvatarView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 04/01/26.
//

import SwiftUI

struct JuruAvatarView: View {
    var faceManager: FaceTrackingManager
    
    var manualSmileLeft: Double? = nil
    var manualSmileRight: Double? = nil
    var manualPucker: Double? = nil
    
    var size: CGFloat = 200
    var color: Color = .juruTeal
    
    @State private var isBlinking = false
    @State private var blinkTimer = Timer.publish(every: 4.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.juruCardBackground)
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.3), radius: 20, y: 10)
                .overlay(
                    Circle()
                        .stroke(color.opacity(0.1), lineWidth: 4)
                )
            
            HStack(spacing: size * 0.3) {
                EyeView(isBlinking: isBlinking, isSmiling: effectiveSmileLeft > 0.2)
                EyeView(isBlinking: isBlinking, isSmiling: effectiveSmileRight > 0.2)
            }
            .offset(y: -size * 0.1)
            
            AsymmetricMouthView(
                smileLeft: effectiveSmileLeft,
                smileRight: effectiveSmileRight,
                pucker: effectivePucker
            )
            .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
            .frame(width: size * 0.5, height: size * 0.4)
            .offset(y: size * 0.15)
        }
        .onReceive(blinkTimer) { _ in
            if Bool.random() {
                withAnimation(.linear(duration: 0.1)) { isBlinking = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.linear(duration: 0.1)) { isBlinking = false }
                }
            }
        }
    }
    
    var effectiveSmileLeft: Double { manualSmileLeft ?? Double(faceManager.smileLeft) }
    var effectiveSmileRight: Double { manualSmileRight ?? Double(faceManager.smileRight) }
    var effectivePucker: Double { manualPucker ?? Double(faceManager.mouthPucker) }
}

struct EyeView: View {
    var isBlinking: Bool
    var isSmiling: Bool
    
    var body: some View {
        ZStack {
            if isBlinking {
                Capsule().frame(width: 24, height: 6).foregroundStyle(Color.juruLead)
            } else if isSmiling {
                Image(systemName: "chevron.up")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.juruTeal)
            } else {
                Capsule().frame(width: 18, height: 28).foregroundStyle(Color.juruLead)
            }
        }
    }
}

struct AsymmetricMouthView: Shape {
    var smileLeft: Double
    var smileRight: Double
    var pucker: Double
    
    var animatableData: AnimatablePair<Double, AnimatablePair<Double, Double>> {
        get { AnimatablePair(smileLeft, AnimatablePair(smileRight, pucker)) }
        set {
            smileLeft = newValue.first
            smileRight = newValue.second.first
            pucker = newValue.second.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        if pucker > 0.3 {
            let size = w * 0.3
            let x = (w - size) / 2
            let y = (h - size) / 2
            path.addEllipse(in: CGRect(x: x, y: y, width: size, height: size))
            return path
        }
        
        let startX: CGFloat = 0
        let endX: CGFloat = w
        
        let leftY = h * 0.4 - (CGFloat(smileLeft) * h * 0.3)
        let rightY = h * 0.4 - (CGFloat(smileRight) * h * 0.3)
        
        let controlY = h * 0.4 + (CGFloat(max(smileLeft, smileRight)) * h * 0.4)
        
        path.move(to: CGPoint(x: startX, y: leftY))
        path.addQuadCurve(
            to: CGPoint(x: endX, y: rightY),
            control: CGPoint(x: w / 2, y: controlY)
        )
        
        return path
    }
}
