//
//  DesignSystem.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 31/12/25.
//

import SwiftUI
import UIKit

extension Color {
    static let juruCoral = Color(red: 1.0, green: 0.435, blue: 0.38)
    static let juruTeal = Color(red: 0.0, green: 0.545, blue: 0.545)
    static let juruSand = Color(red: 0.96, green: 0.96, blue: 0.94)
    static let juruLead = Color(red: 0.184, green: 0.31, blue: 0.31)
    
    static let juruDeepForest = Color(red: 0.02, green: 0.08, blue: 0.08)
    static let juruDarkCard = Color(red: 0.06, green: 0.15, blue: 0.15)
    static let juruLightText = Color(red: 0.96, green: 0.96, blue: 0.94)

    static var juruBackground: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(juruDeepForest) : UIColor(juruSand)
        })
    }
    
    static var juruText: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(juruLightText) : UIColor(juruLead)
        })
    }
    
    static var juruCardBackground: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(juruDarkCard) : UIColor.white
        })
    }
    
    static var juruSecondaryText: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor.gray : UIColor(juruLead).withAlphaComponent(0.6)
        })
    }
}

struct JuruCardModifier: ViewModifier {
    let isActive: Bool
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(isActive ? Color.juruTeal.opacity(0.15) : Color.juruCardBackground)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(borderColor, lineWidth: isActive ? 4 : 1)
            )
            .shadow(color: shadowColor, radius: isActive ? 12 : 8, x: 0, y: 4)
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isActive)
    }
    
    private var borderColor: Color {
        if isActive { return .juruTeal }
        return colorScheme == .dark ? .white.opacity(0.1) : .gray.opacity(0.2)
    }
    
    private var shadowColor: Color {
        if isActive { return .juruTeal.opacity(0.3) }
        return .black.opacity(colorScheme == .dark ? 0.3 : 0.05)
    }
}
