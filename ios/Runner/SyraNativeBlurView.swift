import UIKit
import Flutter

final class SyraNativeBlurView: NSObject, FlutterPlatformView {
  private let blurView: UIVisualEffectView

  init(frame: CGRect, viewId: Int64, args: Any?) {
    // Try different blur styles:
    // .systemUltraThinMaterialDark - en hafif
    // .systemThinMaterialDark - hafif
    // .systemMaterialDark - orta
    // .systemThickMaterialDark - yoğun
    // .systemChromeMaterialDark - en yoğun
    // .dark - klasik iOS blur
    
    let effect = UIBlurEffect(style: .dark)
    blurView = UIVisualEffectView(effect: effect)
    blurView.frame = frame
    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    
    // Blur'un üstüne hafif siyah tint ekle
    let tintView = UIView()
    tintView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    tintView.frame = blurView.bounds
    tintView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    blurView.contentView.addSubview(tintView)
    
    super.init()
  }

  func view() -> UIView { blurView }
}