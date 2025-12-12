import SwiftUI

/// Simple "press" feel for SYRA buttons (scale + opacity).
struct SyraButtonPressStyle: ButtonStyle {
    var scale: CGFloat = 0.98
    var pressedOpacity: Double = 0.92

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.85), value: configuration.isPressed)
    }
}
