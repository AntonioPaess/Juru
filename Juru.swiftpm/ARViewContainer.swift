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
        // Cria a View (ela cria sua própria sessão automaticamente)
        let arView = ARView(frame: .zero)
        
        arView.renderOptions = [
            .disableMotionBlur,
            .disableDepthOfField,
            .disableHDR,
            .disableFaceMesh,
            .disablePersonOcclusion
        ]
        
        arView.automaticallyConfigureSession = false
        manager.start(session: arView.session)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

#Preview {
    ARViewContainer(manager: FaceTrackingManager())
}
