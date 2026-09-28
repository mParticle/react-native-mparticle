import React_RCTAppDelegate
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard
      let windowScene = scene as? UIWindowScene,
      let appDelegate = UIApplication.shared.delegate as? AppDelegate,
      let reactNativeFactory = appDelegate.reactNativeFactory
    else {
      return
    }

    let window = UIWindow(windowScene: windowScene)
    self.window = window

    // Keep this alias while React Native 0.84 contains APIs that read the application
    // delegate's window even when UIKit scenes own its lifecycle.
    appDelegate.window = window
    reactNativeFactory.startReactNative(
      withModuleName: "MParticleSample",
      in: window,
      launchOptions: appDelegate.launchOptions
    )
  }
}
