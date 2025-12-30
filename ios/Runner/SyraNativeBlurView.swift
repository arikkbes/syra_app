import UIKit
import Flutter

/// ═══════════════════════════════════════════════════════════════
/// SYRA NATIVE BLUR VIEW - iOS UIVisualEffectView with Fade Mask
/// ═══════════════════════════════════════════════════════════════
/// Uses native iOS blur (UIVisualEffectView) with a CAGradientLayer
/// mask to create smooth fade-out at the bottom edge.
/// 
/// This gives Claude-like blur quality with no hard cutoff line.
/// ═══════════════════════════════════════════════════════════════

// MARK: - Custom container view that handles layout
private class BlurContainerView: UIView {
    let blurView: UIVisualEffectView
    let gradientMask: CAGradientLayer
    
    override init(frame: CGRect) {
        // Native iOS blur - systemMaterialDark for more visible blur effect
        // Options: .systemUltraThinMaterialDark (subtle), .systemThinMaterialDark, .systemMaterialDark (stronger)
        let effect = UIBlurEffect(style: .systemThinMaterialDark)
        blurView = UIVisualEffectView(effect: effect)
        
        // Gradient mask for fade-out at bottom
        // Black = visible, Clear = invisible
        gradientMask = CAGradientLayer()
        gradientMask.colors = [
            UIColor.black.cgColor,      // Top: fully visible
            UIColor.black.cgColor,      // Keep solid for most of the height
            UIColor.clear.cgColor       // Bottom: fade to invisible
        ]
        // Fade only in the last 30% - keeps blur visible longer
        gradientMask.locations = [0.0, 0.70, 1.0]
        gradientMask.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientMask.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        super.init(frame: frame)
        
        backgroundColor = .clear
        clipsToBounds = true
        
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurView)
        
        gradientMask.frame = bounds
        layer.mask = gradientMask
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Update gradient mask frame when bounds change
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientMask.frame = bounds
        blurView.frame = bounds
        CATransaction.commit()
    }
}

// MARK: - Flutter Platform View
final class SyraNativeBlurView: NSObject, FlutterPlatformView {
    private let containerView: BlurContainerView
    
    init(frame: CGRect, viewId: Int64, args: Any?) {
        containerView = BlurContainerView(frame: frame)
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        super.init()
    }
    
    func view() -> UIView {
        containerView
    }
}
