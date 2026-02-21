//
//  FaceTrackingManager.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

@preconcurrency import ARKit
import SwiftUI
import Observation

enum FaceGesture: String, Codable, Sendable, CaseIterable {
    case browUp
    case pucker
}

// Estados da interação do Bico
enum PuckerState {
    case idle
    case charging
    case readyToSelect
    case readyToBack
    case cooldown
}

private struct GestureConfig {
    static let selectTime = AppConfig.Timing.selectHoldDuration
    static let backTime = AppConfig.Timing.backHoldDuration

    static let browThreshold = AppConfig.Thresholds.browDefault
    static let puckerThreshold = AppConfig.Thresholds.puckerDefault
    static let throttleInterval = AppConfig.Thresholds.throttleInterval
    static let minCalibrationValue = AppConfig.Thresholds.minCalibrationValue
}

struct UserCalibration: Codable {
    // Máximos (Quando o usuário faz o gesto)
    var thresholds: [FaceGesture: Double] = [
        .browUp: 0.5,
        .pucker: 0.5
    ]
    // Mínimos (O rosto do usuário relaxado) - A "Tara"
    var restingBase: [FaceGesture: Double] = [
        .browUp: 0.0,
        .pucker: 0.0
    ]
    
    var triggerFactor: Double = AppConfig.Thresholds.triggerFactor
}

@MainActor
@Observable
class FaceTrackingManager: NSObject, ARSessionDelegate {
    // Valores FINAIS (já com a subtração da base)
    var currentValues: [FaceGesture: Double] = [
        .browUp: 0.0,
        .pucker: 0.0
    ]
    
    // Valores BRUTOS (para debug e calibração da base)
    var rawValues: [FaceGesture: Double] = [
        .browUp: 0.0,
        .pucker: 0.0
    ]
    
    var calibration = UserCalibration() {
        didSet { saveCalibration() }
    }
    
    var isCameraDenied = false
    
    // --- MÁQUINA DE ESTADOS ---
    var puckerState: PuckerState = .idle
    var interactionProgress: Double = 0.0
    
    var currentFocusState: Int = 1
    var isConfirming: Bool = false
    var isBackingOut: Bool = false
    
    var isTriggeringLeft: Bool { currentFocusState == 1 }
    var isTriggeringRight: Bool { currentFocusState == 2 }
    var isTriggeringBack: Bool { puckerState == .readyToBack }

    /// Momentarily true when a brow navigation fires, for UI flash feedback.
    var browFlashTrigger: Bool = false
    
    var mouthPucker: Double { getValue(for: .pucker) }
    var browUp: Double { getValue(for: .browUp) }
    // Mantidos para compatibilidade com interfaces antigas, mas sempre zero
    var smileLeft: Double { 0.0 }
    var smileRight: Double { 0.0 }
    
    weak var currentSession: ARSession?
    private let kCalibrationKey = "UserCalibration"
    private var lastUpdateTime: TimeInterval = 0

    /// Timestamp of the last successful face anchor update from ARKit.
    /// Views check this to detect when face tracking is lost (no updates for > 0.5s).
    var lastFaceDetectedTime: Date = .distantPast

    /// Indicates whether a face is currently being tracked.
    /// Updated to true on each face anchor callback.
    var isFaceCurrentlyTracked: Bool = false

    private var puckerStartTime: Date? = nil
    private var cooldownStartTime: Date? = nil
    private var isBrowRelaxed = true
    
    override init() {
        super.init()
        loadCalibration()

        #if DEBUG
        // In debug mode, suppress "face not detected" overlay initially
        lastFaceDetectedTime = Date()
        isFaceCurrentlyTracked = true
        #endif
    }
    
    /// Starts the ARKit face tracking session with camera permission handling.
    ///
    /// - Note for Swift Playgrounds: When running in Swift Playgrounds for the first time,
    ///   granting camera permission causes the app to close. This is **expected iOS behavior**
    ///   (the system restarts the app process after permission grant). Simply reopen the app
    ///   and it will function normally with the granted permission.
    ///
    /// - Note for Xcode: When running via Xcode on a real device, the permission flow is
    ///   seamless and the app continues without interruption.
    ///
    /// - Parameter session: The ARSession to configure for face tracking.
    func start(session: ARSession) {
        self.currentSession = session
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: runSession(session)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted { self.runSession(session) } else { self.isCameraDenied = true }
                }
            }
        case .denied, .restricted: isCameraDenied = true
        @unknown default: break
        }
    }
    
    private func runSession(_ session: ARSession) {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        session.delegate = self
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = false
        session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    func pause() { currentSession?.pause() }
    
    private func saveCalibration() {
        if let encoded = try? JSONEncoder().encode(calibration) {
            UserDefaults.standard.set(encoded, forKey: kCalibrationKey)
        }
    }
    
    private func loadCalibration() {
        if let savedData = UserDefaults.standard.data(forKey: kCalibrationKey),
           let loaded = try? JSONDecoder().decode(UserCalibration.self, from: savedData) {
            self.calibration = loaded
        }
    }
    
    // Configura o Máximo (Amplitude do movimento)
    func setCalibrationMax(for gesture: FaceGesture, value: Float) {
        // O valor salvo é relativo à base (Amplitude Real)
        let base = calibration.restingBase[gesture] ?? 0.0
        let adjustedValue = max(Double(value) - base, 0.0)
        calibration.thresholds[gesture] = max(adjustedValue, GestureConfig.minCalibrationValue)
    }
    
    // Configura a Base (Rosto Relaxado)
    func setRestingBase(for gesture: FaceGesture, value: Float) {
        calibration.restingBase[gesture] = Double(value)
    }
    
    func getValue(for gesture: FaceGesture) -> Double {
        return currentValues[gesture] ?? 0.0
    }
    
    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let anchor = anchors.first as? ARFaceAnchor else { return }
        let currentTime = ProcessInfo.processInfo.systemUptime

        Task { @MainActor in
            guard currentTime - self.lastUpdateTime > GestureConfig.throttleInterval else { return }
            self.lastUpdateTime = currentTime

            self.lastFaceDetectedTime = Date()
            self.isFaceCurrentlyTracked = true
            
            // 1. Captura BRUTA
            let rawBrow = anchor.blendShapes[.browInnerUp]?.doubleValue ?? 0.0
            let rawPucker = anchor.blendShapes[.mouthPucker]?.doubleValue ?? 0.0
            
            self.rawValues = [.browUp: rawBrow, .pucker: rawPucker]
            
            // 2. Aplica a TARA (Subtrai o repouso)
            // Fórmula: (Bruto - Base) = Sinal Real
            let baseBrow = self.calibration.restingBase[.browUp] ?? 0.0
            let basePucker = self.calibration.restingBase[.pucker] ?? 0.0
            
            let correctedBrow = max(rawBrow - baseBrow, 0.0)
            let correctedPucker = max(rawPucker - basePucker, 0.0)
            
            self.currentValues = [.browUp: correctedBrow, .pucker: correctedPucker]
            
            // 3. Lógica de Trigger (Usando valores corrigidos)
            let browThresh = self.calibration.thresholds[.browUp] ?? GestureConfig.browThreshold
            let puckerThresh = self.calibration.thresholds[.pucker] ?? GestureConfig.puckerThreshold
            
            // --- LÓGICA DE NAVEGAÇÃO ---
            // Mutual exclusion: brow navigation only when pucker is idle
            if self.puckerState == .idle {
                if correctedBrow > (browThresh * self.calibration.triggerFactor) {
                    if self.isBrowRelaxed {
                        self.currentFocusState = (self.currentFocusState == 1) ? 2 : 1
                        self.isBrowRelaxed = false

                        // Flash trigger for instant visual feedback
                        self.browFlashTrigger = true
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(AppConfig.Animation.browFlashResetDelay))
                            self.browFlashTrigger = false
                        }

                        let gen = UIImpactFeedbackGenerator(style: .light)
                        gen.impactOccurred()
                    }
                } else {
                    self.isBrowRelaxed = true
                }
            } else {
                // During active pucker, still track brow relaxation state
                if correctedBrow <= (browThresh * self.calibration.triggerFactor) {
                    self.isBrowRelaxed = true
                }
            }
            
            // --- LÓGICA DE AÇÃO (MÁQUINA DE ESTADOS) ---
            // Mutual exclusion: don't start pucker if brow just fired
            let isPuckering = correctedPucker > (puckerThresh * self.calibration.triggerFactor)
                && !self.browFlashTrigger
            
            switch self.puckerState {
            case .idle:
                if isPuckering {
                    self.puckerStartTime = Date()
                    self.puckerState = .charging
                    self.interactionProgress = 0.0
                }
                
            case .charging, .readyToSelect, .readyToBack:
                if isPuckering {
                    guard let startTime = self.puckerStartTime else { return }
                    let duration = Date().timeIntervalSince(startTime)
                    
                    if duration < GestureConfig.selectTime {
                        self.puckerState = .charging
                        self.interactionProgress = duration / GestureConfig.selectTime
                    } else if duration < GestureConfig.backTime {
                        if self.puckerState != .readyToSelect {
                            let gen = UIImpactFeedbackGenerator(style: .medium)
                            gen.impactOccurred()
                        }
                        self.puckerState = .readyToSelect
                        let relativeTime = duration - GestureConfig.selectTime
                        let span = GestureConfig.backTime - GestureConfig.selectTime
                        self.interactionProgress = relativeTime / span
                    } else {
                        if self.puckerState != .readyToBack {
                            let gen = UINotificationFeedbackGenerator()
                            gen.notificationOccurred(.warning)
                        }
                        self.puckerState = .readyToBack
                        self.interactionProgress = 1.0
                    }
                } else {
                    self.executeActionBasedOnState()
                }
                
            case .cooldown:
                let relaxed = correctedPucker < (puckerThresh * AppConfig.Thresholds.puckerHysteresis)
                let timedOut = self.cooldownStartTime.map {
                    Date().timeIntervalSince($0) >= AppConfig.Thresholds.cooldownTimeout
                } ?? false

                if relaxed || timedOut {
                    self.puckerState = .idle
                    self.interactionProgress = 0.0
                    self.puckerStartTime = nil
                    self.cooldownStartTime = nil
                }
            }
        }
    }
    
    private func executeActionBasedOnState() {
        switch puckerState {
        case .readyToSelect:
            self.isConfirming = true
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.isConfirming = false }
            
        case .readyToBack:
            self.isBackingOut = true
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.isBackingOut = false }
            
        default: break
        }
        self.puckerState = .cooldown
        self.cooldownStartTime = Date()
        self.interactionProgress = 0.0
    }
    
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {}

    // MARK: - Simulator Debug Helpers

    #if DEBUG
    /// Simulates a brow raise toggle (navigation) for testing without camera.
    func simulateNavigate() {
        lastFaceDetectedTime = Date()
        isFaceCurrentlyTracked = true
        currentFocusState = (currentFocusState == 1) ? 2 : 1
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }

    /// Simulates a short pucker hold → release (select action) for testing without camera.
    func simulateSelect() {
        lastFaceDetectedTime = Date()
        isFaceCurrentlyTracked = true
        puckerState = .readyToSelect
        interactionProgress = 1.0
        currentValues[.pucker] = 0.8

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.15))
            self.executeActionBasedOnState()
            self.currentValues[.pucker] = 0.0
            try? await Task.sleep(for: .seconds(0.3))
            self.puckerState = .idle
            self.interactionProgress = 0.0
        }
    }

    /// Simulates a long pucker hold → release (undo/back action) for testing without camera.
    func simulateUndo() {
        lastFaceDetectedTime = Date()
        isFaceCurrentlyTracked = true
        puckerState = .readyToBack
        interactionProgress = 1.0
        currentValues[.pucker] = 0.8

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.15))
            self.executeActionBasedOnState()
            self.currentValues[.pucker] = 0.0
            try? await Task.sleep(for: .seconds(0.3))
            self.puckerState = .idle
            self.interactionProgress = 0.0
        }
    }
    #endif
}
