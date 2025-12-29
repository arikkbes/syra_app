import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register native blur view for iOS premium blur effect
    let registrar = self.registrar(forPlugin: "SyraNativeBlur")!
    let factory = SyraNativeBlurViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "syra_native_blur_view")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
