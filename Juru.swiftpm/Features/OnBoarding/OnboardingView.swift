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
    @State private var animateBlobs = false
    
    var body: some View {
        ZStack {
            Color.juruBackground.ignoresSafeArea()
            
            // Dynamic Background (Breathing Blobs)
            ZStack {
                Circle()
                    .fill(Color.juruTeal.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .scaleEffect(animateBlobs ? 1.2 : 0.8)
                    .offset(x: -100, y: -200)
                    .blur(radius: 60)
                
                Circle()
                    .fill(Color.juruCoral.opacity(0.15))
                    .frame(width: 350, height: 350)
                    .scaleEffect(animateBlobs ? 1.1 : 0.9)
                    .offset(x: 150, y: 300)
                    .blur(radius: 50)
            }
            .animation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true), value: animateBlobs)
            .onAppear { animateBlobs = true }
            
            // Paged Content
            TabView(selection: $currentPage) {
                // Page 1: Welcome
                OnboardingCard(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Hello, I'm Juru",
                    description: "I help you speak using only your smiles and facial gestures. Communication belongs to everyone.",
                    buttonTitle: "How does it work?",
                    accentColor: .juruTeal,
                    action: { nextPage() }
                )
                .tag(0)
                
                // Page 2: Explanation
                OnboardingCard(
                    icon: "face.smiling.fill",
                    title: "Smiles Become Words",
                    description: "Juru detects micro-expressions. A gentle smile to the left or right allows you to select letters and words.",
                    buttonTitle: "Got it, let's go",
                    accentColor: .juruCoral,
                    action: { nextPage() }
                )
                .tag(1)
                
                // Page 3: Call to Action
                OnboardingCard(
                    icon: "slider.horizontal.3",
                    title: "One Quick Setup",
                    description: "To get started, I need to learn your unique way of smiling. Shall we do a quick calibration?",
                    buttonTitle: "Calibrate Now",
                    accentColor: .juruTeal,
                    action: { onFinished() }
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .transition(.opacity)
    }
    
    func nextPage() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentPage += 1
        }
    }
}

struct OnboardingCard: View {
    let icon: String
    let title: String
    let description: String
    let buttonTitle: String
    let accentColor: Color
    let action: () -> Void
    
    @State private var isAppearing = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Hero Icon
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, 20)
                .symbolEffect(.bounce, value: isAppearing)
                .scaleEffect(isAppearing ? 1.0 : 0.5)
                .opacity(isAppearing ? 1.0 : 0.0)
            
            // Titles
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.juruText)
                
                Text(description)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.juruSecondaryText)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }
            .offset(y: isAppearing ? 0 : 20)
            .opacity(isAppearing ? 1.0 : 0.0)
            
            Spacer()
            
            // Pill Button
            Button(action: action) {
                Text(buttonTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(accentColor)
                    .clipShape(Capsule())
                    .shadow(color: accentColor.opacity(0.4), radius: 12, y: 6)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
            .opacity(isAppearing ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8)) {
                isAppearing = true
            }
        }
    }
}
