//
//  OnboardingView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 04/01/26.
//

import SwiftUI

struct OnboardingView: View {
    var faceManager: FaceTrackingManager
    var onFinished: () -> Void
    
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            Color.juruBackground.ignoresSafeArea()
            
            // Decorative
            GeometryReader { proxy in
                Circle().fill(Color.juruTeal.opacity(0.1)).frame(width: 300, height: 300)
                    .blur(radius: 60).offset(x: -100, y: -100)
                Circle().fill(Color.juruCoral.opacity(0.1)).frame(width: 250, height: 250)
                    .blur(radius: 60).offset(x: proxy.size.width - 150, y: proxy.size.height - 200)
            }
            .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                // Page 1: Emotional Hook
                WelcomeCard(
                    icon: "heart.text.square.fill",
                    title: "Voice for Everyone",
                    description: "Juru was created for people with ALS, paralysis, and limited muscle mobility.\n\nWe believe communication is a fundamental human right.",
                    accentColor: .juruCoral
                ) { withAnimation { currentPage += 1 } }
                .tag(0)
                
                // Page 2: Concept
                WelcomeCard(
                    icon: "face.smiling.fill",
                    title: "Powered by Smiles",
                    description: "Even when speech is difficult, facial micro-expressions often remain intact.\n\nJuru translates your smiles into words.",
                    accentColor: .juruTeal
                ) { withAnimation { currentPage += 1 } }
                .tag(1)
                
                // Page 3: Environment Check
                EnvironmentCheckPage(faceManager: faceManager) {
                    onFinished()
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentPage)
        }
    }
}

// Reuse the existing components from previous answers
struct WelcomeCard: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    let action: () -> Void
    @State private var isAppearing = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            ZStack {
                Circle().fill(Color.white).frame(width: 160, height: 160)
                    .shadow(color: accentColor.opacity(0.3), radius: 20, x: 0, y: 10)
                Image(systemName: icon).font(.system(size: 70)).foregroundStyle(accentColor)
                    .scaleEffect(isAppearing ? 1.0 : 0.5).opacity(isAppearing ? 1.0 : 0.0)
            }
            VStack(spacing: 16) {
                Text(title).font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.juruText).multilineTextAlignment(.center)
                Text(description).font(.body).multilineTextAlignment(.center)
                    .foregroundStyle(Color.juruSecondaryText).padding(.horizontal, 24).lineSpacing(4)
            }
            .offset(y: isAppearing ? 0 : 20).opacity(isAppearing ? 1.0 : 0.0)
            Spacer()
            Button(action: action) {
                Text("Continue").font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity)
                    .padding().background(accentColor).cornerRadius(20)
                    .shadow(color: accentColor.opacity(0.3), radius: 10, y: 5)
            }
            .padding(.horizontal, 40).padding(.bottom, 60)
        }
        .onAppear { withAnimation(.spring(duration: 0.8)) { isAppearing = true } }
    }
}

struct EnvironmentCheckPage: View {
    var faceManager: FaceTrackingManager
    var onFinish: () -> Void
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 32).stroke(Color.juruText.opacity(0.1), lineWidth: 2)
                    .frame(width: 240, height: 320).background(Color.black.opacity(0.05)).cornerRadius(32)
                VStack {
                    Image(systemName: "sun.max.fill").font(.system(size: 60))
                        .foregroundStyle(Color.juruCoral).symbolEffect(.variableColor.iterative.reversing)
                    Text("Lighting Check").font(.headline).foregroundStyle(Color.juruSecondaryText).padding(.top, 10)
                }
            }
            VStack(spacing: 12) {
                Text("One Last Thing").font(.system(size: 32, weight: .bold, design: .rounded)).foregroundStyle(Color.juruText)
                Text("Ensure your face is well-lit. Shadows can affect detection.").multilineTextAlignment(.center)
                    .foregroundStyle(Color.juruSecondaryText).padding(.horizontal)
            }
            Spacer()
            Button(action: onFinish) {
                HStack { Text("Start Calibration"); Image(systemName: "arrow.right") }
                    .font(.headline).foregroundStyle(Color.juruBackground).frame(maxWidth: .infinity)
                    .padding().background(Color.juruText).cornerRadius(20)
            }
            .padding(.horizontal, 40).padding(.bottom, 60)
        }
    }
}
