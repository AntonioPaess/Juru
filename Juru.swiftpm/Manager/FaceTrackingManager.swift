//
//  FaceTrackingManager.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

@preconcurrency import ARKit
import SwiftUI
import Observation

private struct GestureConfig {
    static let deadZone = 0.02
    static let dominanceMargin = 0.1
    static let puckerThreshold = 0.4
    static let throttleInterval = 0.05
    static let minCalibrationValue: Double = 0.1
}

struct UserCalibration: Codable {
    var smileLeftMax: Double = 0.5
    var smileRightMax: Double = 0.5
    var puckerMax: Double = 0.5
    var triggerFactor: Double = 0.6
}

@MainActor
@Observable
class FaceTrackingManager: NSObject, ARSessionDelegate {
    var smileLeft: Double = 0.0
    var smileRight: Double = 0.0
    var mouthPucker: Double = 0.0
    var calibration = UserCalibration() {
        didSet { saveCalibration() }
    }
    var isCameraDenied = false
    
    weak var currentSession: ARSession?
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private var isPuckering = false
    private var lastUpdateTime: TimeInterval = 0
    
    override init() {
        super.init()
        loadCalibration()
    }
    
    // MARK: - Ciclo de Vida
    
    func start(session: ARSession) {
        self.currentSession = session
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            runSession(session)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted { self.runSession(session) }
                    else { self.isCameraDenied = true }
                }
            }
        case .denied, .restricted:
            isCameraDenied = true
        @unknown default:
            break
        }
    }
    
    private func runSession(_ session: ARSession) {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        
        session.delegate = self
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = false
        session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
        feedbackGenerator.prepare()
    }
    
    func pause() {
        currentSession?.pause()
    }
    
    // MARK: - Persistência
    
    var hasSavedCalibration: Bool {
            return UserDefaults.standard.data(forKey: "UserCalibration") != nil
        }
    
    private func saveCalibration() {
        if let encoded = try? JSONEncoder().encode(calibration) {
            UserDefaults.standard.set(encoded, forKey: "UserCalibration")
        }
    }
    
    private func loadCalibration() {
        if let savedData = UserDefaults.standard.data(forKey: "UserCalibration"),
           let loaded = try? JSONDecoder().decode(UserCalibration.self, from: savedData) {
            self.calibration = loaded
        }
    }
    
    func setCalibrationMax(for gesture: String, value: Float) {
        let val = Double(value)
        switch gesture {
        case "smileLeft": calibration.smileLeftMax = max(val, GestureConfig.minCalibrationValue)
        case "smileRight": calibration.smileRightMax = max(val, GestureConfig.minCalibrationValue)
        case "pucker": calibration.puckerMax = max(val, GestureConfig.minCalibrationValue)
        default: break
        }
    }
    
    // MARK: - Gatilhos
    
    var isTriggeringLeft: Bool {
        return smileLeft > (calibration.smileLeftMax * calibration.triggerFactor)
    }
    var isTriggeringRight: Bool {
        return smileRight > (calibration.smileRightMax * calibration.triggerFactor)
    }
    var isTriggeringBack: Bool {
        return mouthPucker > (calibration.puckerMax * calibration.triggerFactor)
    }
    
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
            
            if sLeft > GestureConfig.deadZone && sLeft > (sRight + GestureConfig.dominanceMargin) {
                self.smileRight = sLeft
                self.smileLeft = 0.0
            }
            else if sRight > GestureConfig.deadZone && sRight > (sLeft + GestureConfig.dominanceMargin) {
                self.smileLeft = sRight
                self.smileRight = 0.0
            }
            else {
                self.smileLeft = 0.0
                self.smileRight = 0.0
            }
            
            if pucker > GestureConfig.puckerThreshold {
                self.mouthPucker = pucker
                if !self.isPuckering {
                    self.feedbackGenerator.impactOccurred()
                    self.isPuckering = true
                }
            } else {
                self.mouthPucker = 0.0
                self.isPuckering = false
            }
        }
    }
    
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {}
}
