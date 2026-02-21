//
//  PortraitLockOverlay.swift
//  Juru
//
//  Blocking overlay shown when the device is held in portrait orientation.
//  Juru requires landscape mode for proper face tracking (camera at top/left).
//

import SwiftUI

/// Blocking overlay that instructs the user to rotate the device to landscape.
///
/// Although `Package.swift` restricts to landscape orientations, some contexts
/// (Swift Playgrounds, multitasking) may still present a narrow aspect ratio.
/// This overlay acts as a safety net, checking `GeometryProxy` dimensions.
struct PortraitLockOverlay: View {
    let isPortrait: Bool

    var body: some View {
        if isPortrait {
            ZStack {
                Color.black.opacity(0.9)
                    .ignoresSafeArea()

                VStack(spacing: AppConfig.Padding.xl) {
                    Image(systemName: "rectangle.landscape.rotate")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.juruTeal)
                        .symbolEffect(.pulse)

                    VStack(spacing: AppConfig.Padding.sm) {
                        Text("Rotate Your Device")
                            .font(.juruFont(.title2, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Juru works best in landscape mode.\nPlease rotate your device with the camera on top.")
                            .font(.juruFont(.body))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppConfig.Padding.xxxl)
                    }

                    HStack(spacing: AppConfig.Padding.md) {
                        HStack(spacing: AppConfig.Padding.xs) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: AppConfig.Padding.md))
                                .foregroundStyle(Color.juruGold)
                            Text("Camera on top")
                                .font(.juruFont(.caption, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.horizontal, AppConfig.Padding.md)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())

                        HStack(spacing: AppConfig.Padding.xs) {
                            Image(systemName: "ipad.landscape")
                                .font(.system(size: AppConfig.Padding.md))
                                .foregroundStyle(Color.juruGold)
                            Text("Landscape mode")
                                .font(.juruFont(.caption, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.horizontal, AppConfig.Padding.md)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .padding(.top, AppConfig.Padding.xs)
                }
                .padding(AppConfig.Padding.xl)
            }
            .transition(.opacity)
        }
    }
}
