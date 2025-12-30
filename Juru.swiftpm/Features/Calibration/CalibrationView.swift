//
//  CalibrationView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

import SwiftUI

struct CalibrationView: View {
    var faceManager: FaceTrackingManager
    var onCalibrationComplete: () -> Void
    
    enum CalibState { case neutral, smileLeft, smileRight, pucker, finished }
    @State private var state: CalibState = .neutral
    @State private var maxValue: Float = 0.0
    
    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Câmera
                ZStack {
                    ARViewContainer(manager: faceManager)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    
                    VStack {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("TRACKING_ACTIVE").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(.white.opacity(0.5))
                                Text("60 FPS").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(.cyan)
                            }
                            Spacer()
                        }
                        Spacer()
                    }.padding()
                }
                .frame(height: 350).padding(.horizontal).padding(.top, 20)
                
                Text(instructionText)
                    .font(.system(size: 18, weight: .medium)).foregroundStyle(.white).multilineTextAlignment(.center)
                    .frame(height: 60).padding(.horizontal)
                
                // ✅ Usando Componentes
                VStack(spacing: 25) {
                    HUDProgressBar(label: "MOUTH SMILE LEFT", value: Float(faceManager.smileLeft), color: .cyan, isActive: state == .smileLeft)
                    HUDProgressBar(label: "MOUTH SMILE RIGHT", value: Float(faceManager.smileRight), color: Color(red: 1.0, green: 0.27, blue: 0.23), isActive: state == .smileRight)
                    HUDProgressBar(label: "MOUTH PUCKER", value: Float(faceManager.mouthPucker), color: Color(red: 0.2, green: 0.84, blue: 0.29), isActive: state == .pucker)
                }
                .padding(.horizontal, 24).padding(.top, 10)
                
                Spacer()
                
                Button(action: nextStep) {
                    Text(buttonText)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black).frame(maxWidth: .infinity).frame(height: 50)
                        .background(Color.white).cornerRadius(12)
                }
                .padding(.horizontal, 24).padding(.bottom, 20)
            }
        }
        .onChange(of: faceManager.smileLeft) { _, new in if state == .smileLeft { maxValue = max(maxValue, Float(new)) } }
        .onChange(of: faceManager.smileRight) { _, new in if state == .smileRight { maxValue = max(maxValue, Float(new)) } }
        .onChange(of: faceManager.mouthPucker) { _, new in if state == .pucker { maxValue = max(maxValue, Float(new)) } }
    }
    
    var instructionText: String {
        switch state {
        case .neutral: return "Relax face to define neutral state."
        case .smileLeft: return "Smile to the LEFT."
        case .smileRight: return "Smile to the RIGHT."
        case .pucker: return "Make a PUCKER (Kiss)."
        case .finished: return "Calibration Complete."
        }
    }
    
    var buttonText: String { state == .finished ? "START APP" : "NEXT STEP" }
    
    func nextStep() {
        switch state {
        case .neutral: state = .smileLeft; maxValue = 0
        case .smileLeft: faceManager.setCalibrationMax(for: "smileLeft", value: maxValue); state = .smileRight; maxValue = 0
        case .smileRight: faceManager.setCalibrationMax(for: "smileRight", value: maxValue); state = .pucker; maxValue = 0
        case .pucker: faceManager.setCalibrationMax(for: "pucker", value: maxValue); state = .finished
        case .finished: onCalibrationComplete()
        }
    }
}
