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
    case smileLeft
    case smileRight
    case pucker
}

private struct GestureConfig {
    static let deadZone = 0.02
    static let dominanceMargin = 0.1
    static let puckerThreshold = 0.4
    static let throttleInterval = 0.05
    static let minCalibrationValue: Double = 0.1
}

struct UserCalibration: Codable {
    var thresholds: [FaceGesture: Double] = [
        .smileLeft: 0.5,
        .smileRight: 0.5,
        .pucker: 0.5
    ]
    var triggerFactor: Double = 0.6
}

@MainActor
@Observable
class FaceTrackingManager: NSObject, ARSessionDelegate {
    var currentValues: [FaceGesture: Double] = [
        .smileLeft: 0.0,
        .smileRight: 0.0,
        .pucker: 0.0
    ]
    
    var calibration = UserCalibration() {
        didSet { saveCalibration() }
    }
    
    var isCameraDenied = false
    var triggerHaptic: Int = 0
    
    weak var currentSession: ARSession?
    private var isPuckering = false
    private var lastUpdateTime: TimeInterval = 0
    private let kCalibrationKey = "UserCalibration"
    
    override init() {
        super.init()
        loadCalibration()
    }
    
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
    
    var hasSavedCalibration: Bool {
        return UserDefaults.standard.data(forKey: kCalibrationKey) != nil
    }
    
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
    
    func setCalibrationMax(for gesture: FaceGesture, value: Float) {
        calibration.thresholds[gesture] = max(Double(value), GestureConfig.minCalibrationValue)
    }
    
    // MARK: - Helpers de Acesso Seguro
    func getValue(for gesture: FaceGesture) -> Double {
        return currentValues[gesture] ?? 0.0
    }
    
    func isTriggering(_ gesture: FaceGesture) -> Bool {
        let current = getValue(for: gesture)
        let max = calibration.thresholds[gesture] ?? 0.5
        return current > (max * calibration.triggerFactor)
    }
    
    var isTriggeringLeft: Bool { isTriggering(.smileLeft) }
    var isTriggeringRight: Bool { isTriggering(.smileRight) }
    var isTriggeringBack: Bool { isTriggering(.pucker) }
    
    var smileLeft: Double { getValue(for: .smileLeft) }
    var smileRight: Double { getValue(for: .smileRight) }
    var mouthPucker: Double { getValue(for: .pucker) }
    
    // MARK: - ARSessionDelegate
    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let anchor = anchors.first as? ARFaceAnchor else { return }
        let currentTime = ProcessInfo.processInfo.systemUptime
        
        Task { @MainActor in
            guard currentTime - self.lastUpdateTime > GestureConfig.throttleInterval else { return }
            self.lastUpdateTime = currentTime
            
            let sLeft = anchor.blendShapes[.mouthSmileLeft]?.doubleValue ?? 0.0
            let sRight = anchor.blendShapes[.mouthSmileRight]?.doubleValue ?? 0.0
            let pucker = anchor.blendShapes[.mouthPucker]?.doubleValue ?? 0.0
            
            var newValues: [FaceGesture: Double] = [.smileLeft: 0.0, .smileRight: 0.0, .pucker: 0.0]
            
            if sLeft > GestureConfig.deadZone && sLeft > (sRight + GestureConfig.dominanceMargin) {
                newValues[.smileRight] = sLeft
            } else if sRight > GestureConfig.deadZone && sRight > (sLeft + GestureConfig.dominanceMargin) {
                newValues[.smileLeft] = sRight
            }
            
            if pucker > GestureConfig.puckerThreshold {
                newValues[.pucker] = pucker
                if !self.isPuckering {
                    self.triggerHaptic += 1
                    self.isPuckering = true
                }
            } else {
                self.isPuckering = false
            }
            
            self.currentValues = newValues
        }
    }
    
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {}
}
