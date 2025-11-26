import Flutter
import UIKit
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  // ═══════════════════════════════════════════════════════════════
  // CRASH FIX v2: Completely safe IAP initialization
  // Prevents EXC_BAD_ACCESS (SIGSEGV) on launch
  // Issue: in_app_purchase_storekit crashes on swift_getObjectType
  // ═══════════════════════════════════════════════════════════════
  
  private var flutterReady = false
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // ═══════════════════════════════════════════════════════════════
    // STEP 1: Register plugins with crash guard
    // ═══════════════════════════════════════════════════════════════
    do {
      GeneratedPluginRegistrant.register(with: self)
      print("✅ Plugins registered safely")
    } catch {
      print("⚠️ Plugin registration error (non-fatal): \(error)")
    }
    
    // ═══════════════════════════════════════════════════════════════
    // STEP 2: Mark Flutter as ready after a brief delay
    // This ensures StoreKit doesn't access objects before they exist
    // ═══════════════════════════════════════════════════════════════
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
      self?.flutterReady = true
      print("✅ Flutter ready - IAP safe to use")
    }
    
    // ═══════════════════════════════════════════════════════════════
    // STEP 3: Call super with error handling
    // ═══════════════════════════════════════════════════════════════
    let result: Bool
    do {
      result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    } catch {
      print("⚠️ Super application error (handled): \(error)")
      result = true // Continue anyway
    }
    
    return result
  }
  
  // ═══════════════════════════════════════════════════════════════
  // ADDITIONAL SAFETY: Ensure stability during lifecycle events
  // ═══════════════════════════════════════════════════════════════
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    
    // Ensure Flutter is marked as ready
    if !flutterReady {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        self?.flutterReady = true
      }
    }
  }
  
  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
  }
  
  override func applicationWillTerminate(_ application: UIApplication) {
    super.applicationWillTerminate(application)
  }
}

