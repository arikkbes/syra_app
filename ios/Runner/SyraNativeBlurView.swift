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

final class SyraNativeBlurView: NSObject, FlutterPlatformView {
    private let containerView: UIView
    private let blurView: UIVisualEffectView
    private let gradientMask: CAGradientLayer
    
    init(frame: CGRect, viewId: Int64, args: Any?) {
        // Container to hold blur + apply mask
        containerView = UIView(frame: frame)
        containerView.backgroundColor = .clear
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Native iOS blur - systemUltraThinMaterialDark for subtle glass effect
        let effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        blurView = UIVisualEffectView(effect: effect)
        blurView.frame = containerView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Gradient mask for fade-out at bottom
        // Black = visible, Clear = invisible
        gradientMask = CAGradientLayer()
        gradientMask.frame = containerView.bounds
        gradientMask.colors = [
            UIColor.black.cgColor,      // Top: fully visible
            UIColor.black.cgColor,      // Keep solid until fade starts
            UIColor.clear.cgColor       // Bottom: fade to invisible
        ]
        // Fade starts at ~60% from top, ends at bottom
        // Adjust these values to control fade position
        gradientMask.locations = [0.0, 0.55, 1.0]
        gradientMask.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientMask.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        super.init()
        
        containerView.addSubview(blurView)
        containerView.layer.mask = gradientMask
    }
    
    func view() -> UIView {
        containerView
    }
    
    /// Update mask frame when view resizes
    func updateMaskFrame() {
        gradientMask.frame = containerView.bounds
    }
}

// MARK: - Layout update handling
extension SyraNativeBlurView {
    /// Called when the view's bounds change
    func viewDidLayoutSubviews() {
        gradientMask.frame = containerView.bounds
        blurView.frame = containerView.bounds
    }
}
