import SwiftUI

enum Motion {
    static let snappy = Animation.spring(response: 0.32, dampingFraction: 0.78)
    static let gentle = Animation.spring(response: 0.55, dampingFraction: 0.85)
    static let bouncy = Animation.spring(response: 0.45, dampingFraction: 0.6)
    static let interactive = Animation.interactiveSpring(response: 0.25, dampingFraction: 0.7)
    static let easeStandard = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.35)
}
