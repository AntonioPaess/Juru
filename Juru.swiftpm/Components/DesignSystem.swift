//
//  DesignSystem.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 31/12/25.
//

import SwiftUI
import UIKit

extension Color {
    static var juruTeal: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.25, green: 0.65, blue: 0.60, alpha: 1.0)
            : UIColor(red: 0.00, green: 0.50, blue: 0.50, alpha: 1.0)
        })
    }
    
    static var juruCoral: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.90, green: 0.55, blue: 0.50, alpha: 1.0)
            : UIColor(red: 0.90, green: 0.35, blue: 0.30, alpha: 1.0)
        })
    }
    
    static var juruGold: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.80, blue: 0.40, alpha: 1.0)
            : UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0)
        })
    }

    static var juruBackground: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.12, blue: 0.11, alpha: 1.0)
            : UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
        })
    }
    
    static var juruCardBackground: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.18, blue: 0.17, alpha: 1.0)
            : UIColor.white
        })
    }
    
    static var juruText: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.92, blue: 0.88, alpha: 1.0)
            : UIColor(red: 0.10, green: 0.20, blue: 0.20, alpha: 1.0)
        })
    }
    
    static var juruSecondaryText: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.92, blue: 0.88, alpha: 0.6)
            : UIColor(red: 0.18, green: 0.31, blue: 0.31, alpha: 0.7)
        })
    }
    
    static let juruLead = Color(red: 0.184, green: 0.31, blue: 0.31)
}

struct JuruCardModifier: ViewModifier {
    let isActive: Bool
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(isActive ? Color.juruTeal.opacity(0.15) : Color.juruCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppConfig.CornerRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppConfig.CornerRadius.md, style: .continuous)
                    .stroke(borderColor, lineWidth: isActive ? 3 : 1)
            )
            .shadow(
                color: shadowColor,
                radius: isActive ? AppConfig.Padding.sm : AppConfig.Padding.xs,
                x: 0,
                y: isActive ? 6 : 3
            )
            .scaleEffect(isActive ? 1.02 : 1.0)
            .animation(.spring(response: AppConfig.Animation.springResponse, dampingFraction: AppConfig.Animation.springDamping), value: isActive)
    }
    
    private var borderColor: Color {
        if isActive { return .juruTeal }
        return colorScheme == .dark ? .white.opacity(0.08) : .black.opacity(0.04)
    }
    
    private var shadowColor: Color {
        if isActive { return .juruTeal.opacity(0.3) }
        return colorScheme == .dark ? Color.black.opacity(0.4) : Color.juruLead.opacity(0.08)
    }
}

extension Font {
    static func juruFont(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        return .system(style, design: .rounded).weight(weight)
    }
}
