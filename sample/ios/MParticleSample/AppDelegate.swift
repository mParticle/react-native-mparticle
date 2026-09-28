import React
import React_RCTAppDelegate
import ReactAppDependencyProvider
import UIKit
import mParticle_Apple_SDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  // React Native 0.84 still consults the application delegate's window in a few
  // places. SceneDelegate owns the window and mirrors it here for compatibility.
  var window: UIWindow?
  var reactNativeDelegate: ReactNativeDelegate?
  var reactNativeFactory: RCTReactNativeFactory?
  var launchOptions: [UIApplication.LaunchOptionsKey: Any]?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    let delegate = ReactNativeDelegate()
    delegate.dependencyProvider = RCTAppDependencyProvider()

    reactNativeDelegate = delegate
    reactNativeFactory = RCTReactNativeFactory(delegate: delegate)
    self.launchOptions = launchOptions

    let environment = ProcessInfo.processInfo.environment
    let options = MParticleOptions(
      key: environment["MPARTICLE_KEY"] ?? "REPLACE_ME",
      secret: environment["MPARTICLE_SECRET"] ?? "REPLACE_ME"
    )
    let networkOptions = MPNetworkOptions()
    networkOptions.pinningDisabled = true
    options.networkOptions = networkOptions
    options.logLevel = .verbose
    options.environment = .production

    let request = MPIdentityApiRequest()
    request.email = "email@example.com"
    options.identifyRequest = request
    options.onIdentifyComplete = { apiResult, error in
      NSLog(
        "Identify complete. userId = \(String(describing: apiResult?.user.userId)) "
          + "error = \(String(describing: error))"
      )
    }

    MParticle.sharedInstance().start(with: options)
    MParticle.sharedInstance().logLevel = .verbose
    return true
  }
}

class ReactNativeDelegate: RCTDefaultReactNativeFactoryDelegate {
  override func sourceURL(for bridge: RCTBridge) -> URL? {
    bundleURL()
  }

  override func bundleURL() -> URL? {
#if DEBUG
    RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
#else
    Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
  }
}
