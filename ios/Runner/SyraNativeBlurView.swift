import UIKit
import Flutter

final class SyraNativeBlurView: NSObject, FlutterPlatformView {
  private let container: UIView
  private let blurView: UIVisualEffectView

  init(frame: CGRect, viewId: Int64, args: Any?) {
    container = UIView(frame: frame)
    container.backgroundColor = .clear
    container.isOpaque = false

    let effect = UIBlurEffect(style: .systemMaterialDark)
    blurView = UIVisualEffectView(effect: effect)
    blurView.frame = container.bounds
    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    blurView.backgroundColor = .clear
    blurView.isOpaque = false

    container.addSubview(blurView)
    super.init()
  }

  func view() -> UIView { container }
}