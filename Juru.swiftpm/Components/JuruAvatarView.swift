//
//  JuruAvatarView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 04/01/26.
//

import SwiftUI

/// An animated avatar that mirrors the user's facial expressions.
///
/// The avatar displays:
/// - Animated eyebrows that raise based on `browUp` value
/// - A mouth that transitions between smile and pucker states
/// - Periodic natural blinking for lifelike appearance
///
/// ## Usage Modes
/// - **Live tracking**: Pass `faceManager` and leave `manualBrowUp`/`manualPucker` nil
/// - **Demo mode**: Set `manualBrowUp`/`manualPucker` to override face tracking values
///
/// ## Blink Animation
/// Uses `TimelineView` with controlled intervals to trigger random blinks every ~3.5 seconds.
/// The `lastBlinkTime` state prevents rapid consecutive blinks even if the view re-renders frequently.
struct JuruAvatarView: View {
    var faceManager: FaceTrackingManager

    var manualBrowUp: Double? = nil
    var manualPucker: Double? = nil

    var size: CGFloat = 200
    var color: Color = .juruTeal

    @State private var isBlinking = false
    @State private var lastBlinkTime: Date = .distantPast

    var effectiveBrowUp: Double { manualBrowUp ?? faceManager.browUp }
    var effectivePucker: Double { manualPucker ?? faceManager.mouthPucker }

    /// Minimum interval between blink animations (3.5 seconds)
    private let blinkInterval: TimeInterval = 3.5

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.juruCardBackground, Color.juruCardBackground.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 15)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )

                VStack(spacing: size * 0.15) {
                    HStack(spacing: size * 0.35) {
                        EyeComposite(isBlinking: isBlinking, browUp: effectiveBrowUp, color: color, size: size * 0.12)
                        EyeComposite(isBlinking: isBlinking, browUp: effectiveBrowUp, color: color, size: size * 0.12)
                    }
                    .offset(y: size * 0.05)

                    MouthView(pucker: effectivePucker, color: color)
                        .frame(width: size * 0.3, height: size * 0.2)
                }
                .offset(y: -size * 0.05)
            }
            .onChange(of: timeline.date) { _, newDate in
                let timeSinceLastBlink = newDate.timeIntervalSince(lastBlinkTime)
                if timeSinceLastBlink >= blinkInterval && Bool.random() {
                    lastBlinkTime = newDate
                    withAnimation(.smooth(duration: 0.15)) { isBlinking = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.smooth(duration: 0.15)) { isBlinking = false }
                    }
                }
            }
        }
    }
}

struct EyeComposite: View {
    var isBlinking: Bool
    var browUp: Double
    var color: Color
    var size: CGFloat
    
    var body: some View {
        VStack(spacing: size * 0.5) {
            Capsule()
                .fill(color)
                .frame(width: size * 2.8, height: size * 0.7)
                .shadow(color: color.opacity(0.3), radius: 4, y: 2)
                .offset(y: CGFloat(browUp * -25))
                .rotationEffect(.degrees(browUp * -12))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: browUp)
            
            ZStack {
                if isBlinking {
                    Capsule()
                        .fill(Color.primary.opacity(0.8))
                        .frame(width: size * 2.0, height: size * 0.4)
                } else {
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 2.0, height: size * 2.0)
                        .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
                    
                    Circle()
                        .fill(color)
                        .frame(width: size * 1.1, height: size * 1.1)
                        .overlay(
                            Circle()
                                .fill(.white.opacity(0.8))
                                .frame(width: size * 0.35, height: size * 0.35)
                                .offset(x: size * 0.3, y: -size * 0.3)
                        )
                }
            }
        }
    }
}

struct MouthView: View {
    var pucker: Double
    var color: Color
    
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            
            ZStack {
                if pucker > 0.3 {
                    Circle()
                        .fill(color)
                        .frame(width: w * 0.55, height: w * 0.55)
                        .position(x: w/2, y: h/2)
                        .shadow(color: color.opacity(0.4), radius: 8)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.1, y: h * 0.4))
                        path.addQuadCurve(
                            to: CGPoint(x: w * 0.9, y: h * 0.4),
                            control: CGPoint(x: w/2, y: h * 0.8)
                        )
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .shadow(color: color.opacity(0.2), radius: 2, y: 2)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pucker > 0.3)
        }
    }
}
