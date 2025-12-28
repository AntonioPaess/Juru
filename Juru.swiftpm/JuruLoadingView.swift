//
//  JuruLoadingView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

import SwiftUI

struct JuruLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.pink, Color.orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 2. Content
            VStack(spacing: 20) {
                Image(systemName: "face.smiling.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.white)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .opacity(isAnimating ? 1.0 : 0.8)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Text("Juru")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
                
                Text("Initializing Face Engine...")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                
                // Custom spinner underneath
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .padding(.top, 10)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    JuruLoadingView()
}
