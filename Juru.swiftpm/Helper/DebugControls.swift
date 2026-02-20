//
//  DebugControls.swift
//  Juru
//
//  Debug overlay for testing the app on Simulator (no TrueDepth camera).
//  Provides on-screen buttons to simulate facial gestures and skip app states.
//
//  Automatically enabled on Simulator via #targetEnvironment(simulator).
//  Always disabled on real device — no manual toggle needed.
//

#if DEBUG
import SwiftUI

/// Global debug configuration. Automatically enabled only on Simulator.
enum DebugConfig {
    /// Enabled automatically when running on Simulator; always false on real device.
    #if targetEnvironment(simulator)
    static let isEnabled = true
    static let startState: DebugStartState? = .tutorial
    #else
    static let isEnabled = false
    static let startState: DebugStartState? = nil
    #endif

    enum DebugStartState {
        case calibration
        case tutorial
        case mainApp
    }
}

/// Floating debug control panel for simulating facial gestures on Simulator.
struct SimulatorDebugOverlay: View {
    var faceManager: FaceTrackingManager
    @State private var isCollapsed = true

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if isCollapsed {
                    collapsedButton
                } else {
                    expandedPanel
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 80)
        }
        .allowsHitTesting(true)
    }

    // MARK: - Collapsed

    var collapsedButton: some View {
        Button {
            withAnimation(.spring(response: 0.3)) { isCollapsed = false }
        } label: {
            Image(systemName: "ladybug.fill")
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.orange.opacity(0.9))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        }
    }

    // MARK: - Expanded

    var expandedPanel: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "ladybug.fill")
                    .font(.system(size: 14))
                Text("Debug")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3)) { isCollapsed = true }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .foregroundStyle(.white)

            Divider().background(Color.white.opacity(0.2))

            // State info
            HStack(spacing: 8) {
                statePill("Focus: \(faceManager.currentFocusState == 1 ? "L" : "R")",
                         color: faceManager.currentFocusState == 1 ? .juruTeal : .juruCoral)
                statePill(puckerStateText, color: puckerStateColor)
            }

            // Action buttons
            HStack(spacing: 10) {
                debugButton(
                    icon: "eyebrow",
                    label: "Nav",
                    color: .juruTeal
                ) {
                    faceManager.simulateNavigate()
                }

                debugButton(
                    icon: "mouth.fill",
                    label: "Select",
                    color: .juruTeal
                ) {
                    faceManager.simulateSelect()
                }

                debugButton(
                    icon: "arrow.uturn.backward",
                    label: "Undo",
                    color: .red
                ) {
                    faceManager.simulateUndo()
                }
            }
        }
        .padding(16)
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
        )
        .transition(.scale(scale: 0.5, anchor: .bottomTrailing).combined(with: .opacity))
    }

    // MARK: - Sub-components

    func debugButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.8), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func statePill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.6), in: Capsule())
    }

    var puckerStateText: String {
        switch faceManager.puckerState {
        case .idle: return "Idle"
        case .charging: return "Charging"
        case .readyToSelect: return "Select!"
        case .readyToBack: return "Back!"
        case .cooldown: return "Cooldown"
        }
    }

    var puckerStateColor: Color {
        switch faceManager.puckerState {
        case .idle: return .gray
        case .charging: return .yellow
        case .readyToSelect: return .green
        case .readyToBack: return .red
        case .cooldown: return .blue
        }
    }
}
#endif
