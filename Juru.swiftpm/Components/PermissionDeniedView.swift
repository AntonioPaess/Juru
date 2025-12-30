//
//  PermissionDeniedView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

import SwiftUI

struct PermissionDeniedView: View {
    @Environment(\.openURL) var openURL

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("Camera Access Required")
                .font(.title2)
                .bold()
            
            Text("Juru needs to see your facial gestures to work. Please enable access in Settings.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundStyle(.secondary)
            
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
        .background(.background)
    }
}
