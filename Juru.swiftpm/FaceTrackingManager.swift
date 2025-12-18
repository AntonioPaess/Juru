//
//  FaceTrackingManager.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 14/12/25.
//

import Foundation
import ARKit

@MainActor
@Observable
class FaceTrackingManager: NSObject, @MainActor ARSessionDelegate {
    private let movementThreshold: Double = 0.015
    private var isSessionRunning: Bool = false
    weak var currentSession: ARSession?
    var smileLeft: Double = 0.0
    var mouthPucker: Double = 0.0
    var jawOpen: Double = 0.0
    
    func start(with session: ARSession) {
        if isSessionRunning { return }
        self.currentSession = session
        
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            runSession()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    Task { @MainActor in
                        self?.runSession()
                    }
                }
            }
            
        default:
            print("Permission Denied or restricted")
        }
    }
    
    private func runSession() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        isSessionRunning = true
        
        currentSession?.run(
            configuration,
            options: [.removeExistingAnchors]
        )
    }
    
    func stop() {
        currentSession?.pause()
        isSessionRunning = false
    }
}

extension FaceTrackingManager {
    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let anchor = anchors.first as? ARFaceAnchor else { return }
        
        let newSmileLeft = anchor.blendShapes[.mouthSmileLeft]?.doubleValue ?? 0.0
        let newPuckerValue = anchor.blendShapes[.mouthPucker]?.doubleValue ?? 0.0
        let newJawValue = anchor.blendShapes[.jawOpen]?.doubleValue ?? 0.0
        
        Task { @MainActor in
            if abs(self.smileLeft - newSmileLeft) > movementThreshold {
                self.smileLeft = newSmileLeft
            }
            if abs(self.mouthPucker - newPuckerValue) > movementThreshold {
                self.mouthPucker = newPuckerValue
            }
            if abs(self.jawOpen - newJawValue) > movementThreshold {
                self.jawOpen = newJawValue
            }
        }
    }
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        print("ARKit Erro: \(error.localizedDescription)")
    }
}
