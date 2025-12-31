//
//  BiometricAuth.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 29/12/25.
//

import LocalAuthentication

enum AuthError: Error {
    case notAvailable
    case failed
    case userCancelled
}

struct BiometricAuth {
    static func authenticate() async -> Result<Bool, AuthError> {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .failure(.notAvailable)
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Verify your identity to load your calibration."
            )
            return success ? .success(true) : .failure(.failed)
        } catch {
            return .failure(.failed)
        }
    }
}
