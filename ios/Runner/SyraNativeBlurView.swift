import UIKit
import Flutter

final class SyraNativeBlurView: NSObject, FlutterPlatformView {
  private let blurView: UIVisualEffectView

  init(frame: CGRect, viewId: Int64, args: Any?) {
    // .systemUltraThinMaterialDark = en hafif, cam gibi
    let effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
    blurView = UIVisualEffectView(effect: effect)
    blurView.frame = frame
    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    
    super.init()
  }

  func view() -> UIView { blurView }
}
