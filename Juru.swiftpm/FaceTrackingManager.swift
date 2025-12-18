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
    private var isSessionRunning: Bool = false
    weak var currentSession: ARSession?
    var smileLeft: Double = 0.0
    var smileRight: Double = 0.0
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
        
        let leftValue = anchor.blendShapes[.mouthSmileLeft]?.doubleValue ?? 0.0
        let puckerValue = anchor.blendShapes[.mouthPucker]?.doubleValue ?? 0.0
        let jawValue = anchor.blendShapes[.jawOpen]?.doubleValue ?? 0.0
        
        Task { @MainActor in
            self.smileLeft = leftValue
            self.smileRight = puckerValue
            self.jawOpen = jawValue
        }
    }
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        print("ARKit Erro: \(error.localizedDescription)")
    }
}
