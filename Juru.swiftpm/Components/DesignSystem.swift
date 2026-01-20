//
//  DesignSystem.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 31/12/25.
//

import SwiftUI
import UIKit

extension Color {
    // MARK: - Cores da Marca (Serenidade & Natureza)
    
    // ESQUERDA: Teal
    // Light: Verde-azulado sóbrio.
    // Dark: Sálvia Profundo (Natureza à noite, não neon).
    static var juruTeal: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.25, green: 0.65, blue: 0.60, alpha: 1.0) // Sálvia Suave
            : UIColor(red: 0.00, green: 0.50, blue: 0.50, alpha: 1.0) // Deep Teal
        })
    }
    
    // DIREITA: Coral
    // Light: Terracota.
    // Dark: Salmão Queimado (Acolhedor).
    static var juruCoral: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.90, green: 0.55, blue: 0.50, alpha: 1.0) // Salmão Suave
            : UIColor(red: 0.90, green: 0.35, blue: 0.30, alpha: 1.0) // Deep Coral
        })
    }
    
    // CENTRO: Gold
    // Light: Mel.
    // Dark: Ocre Suave (Luz de vela).
    static var juruGold: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.80, blue: 0.40, alpha: 1.0) // Soft Gold
            : UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0) // Goldenrod
        })
    }

    // MARK: - Fundos e Superfícies
    
    // Light: Areia Quente.
    // Dark: Noite na Floresta (Verde muito escuro e fosco, não preto).
    static var juruBackground: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.12, blue: 0.11, alpha: 1.0) // Deep Matte Forest
            : UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0) // Warm Sand
        })
    }
    
    // Light: Branco Puro.
    // Dark: Verde Musgo Escuro (Camuflado).
    static var juruCardBackground: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.18, blue: 0.17, alpha: 1.0) // Moss Card
            : UIColor.white // Pure White
        })
    }
    
    // MARK: - Tipografia (Leitura Confortável)
    
    // Light: Verde Petróleo Escuro (Não preto).
    // Dark: Marfim/Osso (Não branco puro).
    static var juruText: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.92, blue: 0.88, alpha: 1.0) // Ivory
            : UIColor(red: 0.10, green: 0.20, blue: 0.20, alpha: 1.0) // Deep Slate
        })
    }
    
    static var juruSecondaryText: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.92, blue: 0.88, alpha: 0.6)
            : UIColor(red: 0.18, green: 0.31, blue: 0.31, alpha: 0.7)
        })
    }
    
    // Mantido para compatibilidade
    static let juruLead = Color(red: 0.184, green: 0.31, blue: 0.31)
}

// MARK: - Modifiers (Sombras Suaves)

struct JuruCardModifier: ViewModifier {
    let isActive: Bool
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(isActive ? Color.juruTeal.opacity(0.15) : Color.juruCardBackground)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(borderColor, lineWidth: isActive ? 3 : 1)
            )
            .shadow(
                color: shadowColor,
                radius: isActive ? 12 : 8,
                x: 0,
                y: isActive ? 6 : 3
            )
            .scaleEffect(isActive ? 1.02 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isActive)
    }
    
    private var borderColor: Color {
        if isActive { return .juruTeal }
        // Bordas muito sutis para manter a leveza
        return colorScheme == .dark ? .white.opacity(0.08) : .black.opacity(0.04)
    }
    
    private var shadowColor: Color {
        if isActive { return .juruTeal.opacity(0.3) }
        // Sombras coloridas (não pretas) para dar ar orgânico
        return colorScheme == .dark ? Color.black.opacity(0.4) : Color.juruLead.opacity(0.08)
    }
}
