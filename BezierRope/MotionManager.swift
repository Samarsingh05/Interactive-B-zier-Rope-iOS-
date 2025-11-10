//
//  MotionManager.swift
//  BezierRope
//
//  Created by Samar Singh on 10/11/25.
//


import Foundation
import CoreMotion
import CoreGraphics

final class MotionManager {
    static let shared = MotionManager()
    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    private(set) var pitch: Double = 0
    private(set) var roll: Double = 0
    private(set) var yaw: Double = 0

    private init() {
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
    }

    func startUpdates() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] data, error in
            guard let data = data, error == nil, let self = self else { return }
            let attitude = data.attitude
            self.pitch = attitude.pitch
            self.roll = attitude.roll
            self.yaw = attitude.yaw
        }
    }

    func stopUpdates() {
        manager.stopDeviceMotionUpdates()
    }

    func offset2D(scale: CGFloat = 120) -> CGPoint {
        let dx = CGFloat(roll) * scale
        let dy = CGFloat(-pitch) * scale
        return CGPoint(x: dx, y: dy)
    }
}
