//
//  ARViewContainer.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 14/12/25.
//

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    var manager: FaceTrackingManager
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        arView.renderOptions = [
            .disableMotionBlur,
            .disableDepthOfField,
            .disableHDR,
            .disableFaceMesh,
            .disablePersonOcclusion
        ]
        
        arView.automaticallyConfigureSession = false
        arView.session.delegate = manager
        manager.start(with: arView.session)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

#Preview {
    ARViewContainer(manager: FaceTrackingManager())
}
