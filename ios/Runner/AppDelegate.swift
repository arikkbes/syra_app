import UIKit
import Flutter
import FirebaseCore

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase init (varsa)
    FirebaseApp.configure()

    // TÜM Flutter pluginleri için tek ve doğru kayıt noktası
    GeneratedPluginRegistrant.register(with: self)

    // Üst sınıfın kendi işini yapmasına izin ver
    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // url_launcher, sign-in vb. için
    return super.application(app, open: url, options: options)
  }
}
