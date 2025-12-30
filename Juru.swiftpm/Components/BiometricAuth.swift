//
//  BiometricAuth.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 29/12/25.
//

import LocalAuthentication

struct BiometricAuth {
    static func authenticate() async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return true
        }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Verify your identity to load your calibration."
            )
        } catch {
            return false
        }
    }
}
