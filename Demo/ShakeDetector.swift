//
//  ShakeDetector.swift
//  Demo
//
//  Created by Htun Nay Aung on 8/3/2025.
//

import SwiftUI

// ✅ This UIViewController detects shakes
class ShakeDetector: UIViewController {
    var onShake: (() -> Void)?

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            onShake?()
        }
    }
}

// ✅ SwiftUI Wrapper to Detect Shake Gestures
struct ShakeViewModifier: UIViewControllerRepresentable {
    var onShake: () -> Void

    func makeUIViewController(context: Context) -> ShakeDetector {
        let controller = ShakeDetector()
        controller.onShake = onShake
        return controller
    }

    func updateUIViewController(_ uiViewController: ShakeDetector, context: Context) {}
}

extension View {
    func onShake(_ action: @escaping () -> Void) -> some View {
        self.background(ShakeViewModifier(onShake: action))
    }
}

