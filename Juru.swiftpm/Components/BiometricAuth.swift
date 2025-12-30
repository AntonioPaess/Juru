//
//  BiometricAuth.swift
//  Juru
//
//  Created by Antônio Paes De Andrade on 29/12/25.
//

import LocalAuthentication

class BiometricAuth {
    static func authenticate(completion: @escaping @Sendable (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Verify your identity to load your calibration."

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                Task { @MainActor in
                    completion(success)
                }
            }
        } else {
            print("Biometry not available")
            Task { @MainActor in
                completion(true)
            }
        }
    }
}
