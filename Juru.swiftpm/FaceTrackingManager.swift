//
//  FaceTrackingManager.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

@preconcurrency import ARKit
import SwiftUI
import Observation

enum InputMode: String, CaseIterable {
    case faceMuscles = "Face Muscles"
    case headMovement = "Head Movement"
    case eyeBlink = "Eye Blink"
    case eyeGaze = "Eye Gaze"
}

struct UserCalibration {
    var smileLeftMax: Double = 0.5
    var smileRightMax: Double = 0.5
    var puckerMax: Double = 0.5
    var triggerFactor: Double = 0.6
}

@MainActor
@Observable
class FaceTrackingManager: NSObject, ARSessionDelegate {
    // MARK: - Dados
    var smileLeft: Double = 0.0
    var smileRight: Double = 0.0
    var mouthPucker: Double = 0.0
    
    var headYaw: Double = 0.0
    var headPitch: Double = 0.0
    var blinkLeft: Double = 0.0
    var blinkRight: Double = 0.0
    var eyeYaw: Double = 0.0
    var eyePitch: Double = 0.0

    var currentInputMode: InputMode = .faceMuscles
    var sensitivity: Double = 0.5
    var isCameraDenied = false
    var calibration = UserCalibration()
    
    weak var currentSession: ARSession?
    
    let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    var isPuckering = false
    var lastUpdateTime: TimeInterval = 0
    
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
    
    // MARK: - Gatilhos
    var isTriggeringLeft: Bool {
        let threshold = calibration.smileLeftMax * calibration.triggerFactor
        switch currentInputMode {
        case .faceMuscles: return smileLeft > threshold
        case .headMovement: return headYaw > 0.1
        case .eyeBlink: return blinkLeft > 0.5 && blinkRight < 0.2
        case .eyeGaze: return eyeYaw < -0.2
        }
    }
    
    var isTriggeringRight: Bool {
        let threshold = calibration.smileRightMax * calibration.triggerFactor
        switch currentInputMode {
        case .faceMuscles: return smileRight > threshold
        case .headMovement: return headYaw < -0.1
        case .eyeBlink: return blinkRight > 0.5 && blinkLeft < 0.2
        case .eyeGaze: return eyeYaw > 0.2
        }
    }
    
    var isTriggeringBack: Bool {
        let threshold = calibration.puckerMax * calibration.triggerFactor
        switch currentInputMode {
        case .faceMuscles: return mouthPucker > threshold
        case .headMovement: return headPitch > 0.1
        case .eyeBlink: return blinkLeft > 0.5 && blinkRight > 0.5
        case .eyeGaze: return eyePitch > 0.2
        }
    }
    
    func setCalibrationMax(for gesture: String, value: Float) {
        let val = Double(value)
        switch gesture {
        case "smileLeft": calibration.smileLeftMax = max(val, 0.1)
        case "smileRight": calibration.smileRightMax = max(val, 0.1)
        case "pucker": calibration.puckerMax = max(val, 0.1)
        default: break
        }
    }
    
    // MARK: - ARSessionDelegate
    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let anchor = anchors.first as? ARFaceAnchor else { return }
        let currentTime = ProcessInfo.processInfo.systemUptime
        
        Task { @MainActor in
            guard currentTime - self.lastUpdateTime > 0.05 else { return }
            self.lastUpdateTime = currentTime
            
            let smileLeftValue = anchor.blendShapes[.mouthSmileLeft]?.doubleValue ?? 0.0
            let smileRightValue = anchor.blendShapes[.mouthSmileRight]?.doubleValue ?? 0.0
            let puckerValue = anchor.blendShapes[.mouthPucker]?.doubleValue ?? 0.0
            
            let deadZone = 0.02
            let dominanceMargin = 0.1
            let puckerThreshold = 0.4
            
            if smileLeftValue > deadZone && smileLeftValue > (smileRightValue + dominanceMargin) {
                self.smileRight = smileLeftValue
                self.smileLeft = 0.0
            }
            else if smileRightValue > deadZone && smileRightValue > (smileLeftValue + dominanceMargin) {
                self.smileLeft = smileRightValue
                self.smileRight = 0.0
            }
            else {
                self.smileLeft = 0.0
                self.smileRight = 0.0
            }
            
            if puckerValue > puckerThreshold {
                self.mouthPucker = puckerValue
                if !self.isPuckering {
                    self.feedbackGenerator.impactOccurred()
                    self.isPuckering = true
                }
            } else {
                self.mouthPucker = 0.0
                self.isPuckering = false
            }
            
            self.blinkLeft = anchor.blendShapes[.eyeBlinkLeft]?.doubleValue ?? 0.0
            self.blinkRight = anchor.blendShapes[.eyeBlinkRight]?.doubleValue ?? 0.0
            self.headYaw = Double(atan2(anchor.transform.columns.2.x, anchor.transform.columns.2.z))
            self.headPitch = Double(asin(anchor.transform.columns.2.y))
            self.eyeYaw = Double(anchor.lookAtPoint.x)
            self.eyePitch = Double(anchor.lookAtPoint.y)
        }
    }
    
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        print("ARKit Error: \(error.localizedDescription)")
    }
}
