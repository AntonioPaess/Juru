//
//  GestureAnimations.swift
//  Juru
//
//  Reusable gesture demonstration components.
//  Used in Tutorial and MainTypingView as visual "cheat sheet" for users.
//

import SwiftUI

// MARK: - Gesture Demo Scene

/// Animated demonstration scene showing facial gesture mechanics.
///
/// Displays different demos based on the specified gesture type:
/// - **navigation**: Shows eyebrow raise toggling between menu options
/// - **select**: Shows short pucker hold for selection (1.2s)
/// - **undo**: Shows long pucker hold for undo action (2.0s)
///
/// ## Usage
/// ```swift
/// GestureDemoScene(
///     gestureType: .navigation,
///     faceManager: faceManager,
///     scale: 1.0
/// )
/// ```
struct GestureDemoScene: View {
    enum GestureType {
        case navigation
        case select
        case undo
    }

    let gestureType: GestureType
    var faceManager: FaceTrackingManager
    var scale: CGFloat = 1.0
    var showAvatar: Bool = true

    @State private var demoBrow: Double = 0.0
    @State private var demoPucker: Double = 0.0
    @State private var activeIndex: Int = 0
    @State private var puckerProgress: Double = 0.0
    @State private var puckerColor: Color = .juruTeal
    @State private var lastTickTime: Date = .now

    var body: some View {
        TimelineView(.periodic(from: .now, by: AppConfig.Timing.tickInterval)) { timeline in
            HStack(spacing: AppConfig.Padding.huge * scale) {
                // Left: Visual indicator
                VStack(spacing: AppConfig.Padding.lg * scale) {
                    if gestureType == .navigation {
                        GestureOptionCard(
                            icon: "hand.wave",
                            label: "Hello",
                            isActive: activeIndex == 0,
                            scale: scale
                        )
                        GestureOptionCard(
                            icon: "bolt.heart",
                            label: "Pain",
                            isActive: activeIndex == 1,
                            scale: scale
                        )
                    } else {
                        PuckerProgressRing(
                            progress: puckerProgress,
                            color: puckerColor,
                            isUndo: gestureType == .undo,
                            scale: scale
                        )
                    }
                }
                .frame(width: 140 * scale)

                // Right: Avatar (optional)
                if showAvatar {
                    JuruAvatarView(
                        faceManager: faceManager,
                        manualBrowUp: demoBrow,
                        manualPucker: demoPucker,
                        size: 180 * scale
                    )
                }
            }
            .onChange(of: timeline.date) { _, newDate in
                guard newDate.timeIntervalSince(lastTickTime) >= AppConfig.Timing.tickInterval else { return }
                lastTickTime = newDate
                updateAnimation()
            }
        }
        .onAppear { resetAnimation() }
    }

    private func resetAnimation() {
        demoBrow = 0
        demoPucker = 0
        activeIndex = 0
        puckerProgress = 0
    }

    private func updateAnimation() {
        switch gestureType {
        case .navigation:
            updateNavigationDemo()
        case .select:
            updateSelectDemo()
        case .undo:
            updateUndoDemo()
        }
    }

    private func updateNavigationDemo() {
        let cycle = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 3.0)
        if cycle < 1.0 {
            demoBrow = 0
        } else if cycle < 2.0 {
            withAnimation(.spring(response: AppConfig.Animation.standard)) {
                demoBrow = 1.0
            }
            if cycle >= 1.0 && cycle < 1.05 {
                withAnimation { activeIndex = (activeIndex == 0 ? 1 : 0) }
            }
        } else {
            withAnimation(.spring(response: AppConfig.Animation.springResponse)) {
                demoBrow = 0.0
            }
        }
    }

    private func updateSelectDemo() {
        let cycle = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 3.0)
        if cycle < 0.5 {
            demoPucker = 0
            puckerProgress = 0
        } else if cycle < 2.0 {
            withAnimation(.spring) { demoPucker = 1.0 }
            let holdTime = cycle - 0.5
            if holdTime < AppConfig.Timing.selectHoldDuration {
                puckerColor = .juruTeal
                puckerProgress = holdTime / 1.0
            } else {
                puckerProgress = 1.0
            }
        } else {
            withAnimation(.spring) { demoPucker = 0.0 }
            puckerProgress = 0
        }
    }

    private func updateUndoDemo() {
        let cycle = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 4.5)
        if cycle < 0.5 {
            demoPucker = 0
            puckerProgress = 0
        } else if cycle < 3.5 {
            withAnimation(.spring) { demoPucker = 1.0 }
            let holdTime = cycle - 0.5
            if holdTime < AppConfig.Timing.selectHoldDuration {
                puckerColor = .juruTeal
                puckerProgress = holdTime / 1.0
            } else {
                puckerColor = .red
                puckerProgress = min(1.0, 0.4 + (holdTime - AppConfig.Timing.selectHoldDuration) * 0.4)
            }
        } else {
            withAnimation(.spring) { demoPucker = 0.0 }
            puckerProgress = 0
        }
    }
}

// MARK: - Supporting Components

/// A glassmorphic card component for menu option display in demos.
struct GestureOptionCard: View {
    let icon: String
    let label: String
    let isActive: Bool
    let scale: CGFloat

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(label)
                .font(.system(size: 17 * scale, weight: .bold))
        }
        .foregroundStyle(isActive ? .white : .primary.opacity(0.5))
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppConfig.Padding.md * scale)
        .background(
            RoundedRectangle(cornerRadius: AppConfig.CornerRadius.sm * scale)
                .fill(isActive ? Color.juruTeal : Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConfig.CornerRadius.sm * scale)
                .stroke(isActive ? .white.opacity(0.5) : .clear, lineWidth: 1)
        )
        .shadow(color: isActive ? Color.juruTeal.opacity(0.4) : .clear, radius: 10 * scale)
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(response: AppConfig.Animation.standard), value: isActive)
    }
}

/// Circular progress indicator for pucker gesture duration.
struct PuckerProgressRing: View {
    let progress: Double
    let color: Color
    let isUndo: Bool
    let scale: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 8 * scale)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 8 * scale, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Image(systemName: isUndo && color == .red ? "arrow.uturn.backward" : "checkmark")
                .font(.system(size: 34 * scale, weight: .bold))
                .foregroundStyle(color)
                .opacity(progress > 0.1 ? 1 : 0.3)
                .scaleEffect(progress > 0.1 ? 1.2 : 1.0)
        }
        .frame(width: 120 * scale, height: 120 * scale)
    }
}

// MARK: - Compact Gesture Cheat Sheet

/// A compact horizontal cheat sheet showing gesture icons and labels.
/// Perfect for persistent display during Tutorial or MainTypingView.
struct GestureCheatSheet: View {
    var scale: CGFloat = 1.0
    var showLabels: Bool = true

    var body: some View {
        HStack(spacing: AppConfig.Padding.xl * scale) {
            GestureHint(
                icon: "eyebrow",
                label: "Navigate",
                color: .juruTeal,
                scale: scale,
                showLabel: showLabels
            )

            GestureHint(
                icon: "mouth.fill",
                label: "Select (1s)",
                color: .juruTeal,
                scale: scale,
                showLabel: showLabels
            )

            GestureHint(
                icon: "arrow.uturn.backward",
                label: "Undo (2s)",
                color: .juruCoral,
                scale: scale,
                showLabel: showLabels
            )
        }
        .padding(.horizontal, AppConfig.Padding.lg * scale)
        .padding(.vertical, AppConfig.Padding.sm * scale)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
}

/// Individual gesture hint icon with optional label.
struct GestureHint: View {
    let icon: String
    let label: String
    let color: Color
    var scale: CGFloat = 1.0
    var showLabel: Bool = true

    var body: some View {
        HStack(spacing: 6 * scale) {
            Image(systemName: icon)
                .font(.system(size: 16 * scale, weight: .semibold))
                .foregroundStyle(color)

            if showLabel {
                Text(label)
                    .font(.system(size: 12 * scale, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Animated Gesture Icons

/// Animated eyebrow icon that pulses to indicate navigation.
struct AnimatedBrowIcon: View {
    @State private var isAnimating = false
    var size: CGFloat = 40
    var color: Color = .juruTeal

    var body: some View {
        Image(systemName: "eyebrow")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(color)
            .offset(y: isAnimating ? -4 : 0)
            .animation(
                .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

/// Animated pucker/kiss icon that pulses to indicate selection.
struct AnimatedPuckerIcon: View {
    @State private var isAnimating = false
    var size: CGFloat = 40
    var color: Color = .juruTeal

    var body: some View {
        Image(systemName: "mouth.fill")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(color)
            .scaleEffect(isAnimating ? 1.1 : 0.95)
            .animation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}
