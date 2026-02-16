//
//  FaceNotDetectedOverlay.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 15/02/26.
//

import SwiftUI

/// A reusable overlay displayed when ARKit face tracking loses the user's face.
///
/// Shows a pulsing icon with tips for proper camera positioning and lighting.
/// Used across CalibrationView, TutorialView, and MainTypingView.
///
/// The parent view checks `faceManager.lastFaceDetectedTime` every 200ms.
/// If more than 0.5 seconds pass without a face anchor update, `isVisible` becomes true.
struct FaceNotDetectedOverlay: View {
    let isVisible: Bool
    var scale: CGFloat = 1.0

    var body: some View {
        if isVisible {
            ZStack {
                Color.black.opacity(0.75)
                    .ignoresSafeArea()

                VStack(spacing: 24 * scale) {
                    Image(systemName: "face.dashed")
                        .font(.system(size: 80 * scale))
                        .foregroundStyle(Color.juruCoral)
                        .symbolEffect(.pulse)

                    VStack(spacing: 12 * scale) {
                        Text("Face Not Detected")
                            .font(.juruFont(.title2, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Please position your face in front of the camera")
                            .font(.juruFont(.body))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    HStack(spacing: 16 * scale) {
                        TipItem(icon: "lightbulb.fill", text: "Good lighting", scale: scale)
                        TipItem(icon: "camera.fill", text: "Face the camera", scale: scale)
                    }
                    .padding(.top, 8)
                }
                .padding(32)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}

private struct TipItem: View {
    let icon: String
    let text: String
    var scale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16 * scale))
                .foregroundStyle(Color.juruGold)

            Text(text)
                .font(.juruFont(.caption, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 16 * scale)
        .padding(.vertical, 10 * scale)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
    }
}
