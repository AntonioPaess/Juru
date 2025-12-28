//
//  PermissionDeniedView.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 28/12/25.
//

import SwiftUI

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("Acesso à Câmera Necessário")
                .font(.title2)
                .bold()
            
            Text("O Juru precisa ver seus gestos faciais para funcionar. Por favor, habilite o acesso nos Ajustes.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundStyle(.secondary)
            
            Button("Abrir Ajustes") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
        .background(.background)
    }
}

#Preview {
    PermissionDeniedView()
}
