//
//  ShakeDetector.swift
//  Skip AI (iOS)
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  SHAKE GESTURE DETECTOR - Detects device shake for feedback

import UIKit

/// Detects shake gesture on iOS
class ShakeDetector {
    static let shared = ShakeDetector()
    
    private var onShake: (() -> Void)?
    
    private init() {
        // Swizzle motionEnded to detect shake
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceShaken),
            name: UIDevice.deviceDidShakeNotification,
            object: nil
        )
    }
    
    /// Register shake handler
    /// - Parameter handler: Closure to call when shake detected
    func onShake(_ handler: @escaping () -> Void) {
        onShake = handler
    }
    
    @objc private func deviceShaken() {
        onShake?()
    }
}

/// Custom notification name for shake gesture
extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name("DeviceDidShake")
}

/// Override UIWindow to detect shake
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}

