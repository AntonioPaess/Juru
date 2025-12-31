//
//  JuruLoadingView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

import SwiftUI

struct JuruLoadingView: View {
    @State private var breathingScale: CGFloat = 0.8
    @State private var opacityVal = 0.0
    
    var body: some View {
        ZStack {
            Color.juruBackground.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.juruTeal.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .scaleEffect(breathingScale)
                    
                    Circle()
                        .fill(Color.juruCoral.opacity(0.1))
                        .frame(width: 150, height: 150)
                        .scaleEffect(breathingScale * 0.9)
                        .animation(.easeInOut(duration: 2.5).delay(0.2).repeatForever(), value: breathingScale)

                    Image(systemName: "leaf.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.juruTeal, Color.juruCoral],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(opacityVal)
                }
                
                VStack(spacing: 16) {
                    Text("Juru")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.juruText)
                    
                    Text("Preparing your voice...")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Color.juruSecondaryText)
                }
                .opacity(opacityVal)
                
                Spacer()
                
                ProgressView()
                    .tint(Color.juruTeal)
                    .scaleEffect(1.2)
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                breathingScale = 1.1
            }
            withAnimation(.easeIn(duration: 1.0)) {
                opacityVal = 1.0
            }
        }
    }
}
