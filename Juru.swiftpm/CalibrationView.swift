//
//  CalibrationView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 14/12/25.
//

import SwiftUI

struct CalibrationView: View {
    @Environment(FaceTrackingManager.self) var manager
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        ZStack {
            if manager.isCameraDenied {
                PermissionDeniedView()
            } else {
                ARViewContainer(manager: manager)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView(value: manager.smileLeft, total: 1.0)
                            .tint(.cyan)
                        ProgressView(value: manager.smileRight, total: 1.0)
                            .tint(.red)
                        ProgressView(value: manager.mouthPucker, total: 1.0)
                            .tint(.green)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding()
                }
            }
        }.onChange(of: scenePhase) { old, new in
            if new == .background { manager.stop() }
            else if new == .active {
                if let session = manager.currentSession {
                    manager.start(with: session)
                }
            }
        }
    }
}

#Preview {
    CalibrationView()
}
