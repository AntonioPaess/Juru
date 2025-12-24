//
//  FaceTrackingManager.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 14/12/25.
//

import Foundation
import ARKit
import UIKit

@MainActor
@Observable
class FaceTrackingManager: NSObject, ARSessionDelegate {
    private var isSessionRunning: Bool = false
    weak var currentSession: ARSession?
    var smileLeft: Double = 0.0
    var smileRight: Double = 0.0
    var mouthPucker: Double = 0.0
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private var isPuckering: Bool = false
    private var lastUpdateTime: TimeInterval = 0
    
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
        if let videoFormat = ARFaceTrackingConfiguration.supportedVideoFormats.first(where: { $0.framesPerSecond == 60 }) {
            configuration.videoFormat = videoFormat
            print("Travando ARSession em: \(videoFormat.framesPerSecond) FPS")
        } else {
            print("Aviso: Formato 60FPS não encontrado, usando padrão.")
        }
        
        isSessionRunning = true
        feedbackGenerator.prepare()
        
        currentSession?.run(
            configuration,
            options: [.removeExistingAnchors, .resetTracking]
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
            
            // Lógica do Sorriso
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
        }
    }
}

nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
    print("ARKit Erro: \(error.localizedDescription)")
}
