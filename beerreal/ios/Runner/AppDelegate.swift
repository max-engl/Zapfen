import Flutter
import UIKit
import UserNotifications
import WidgetKit

private let widgetAppGroup = "group.de.maxengl.zapfen.mobile"
private let widgetSnapshotKey = "widgetSnapshot"

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    registerWidgetBridge()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func registerWidgetBridge() {
    guard let registrar = registrar(forPlugin: "BeerrealWidgetBridge") else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "beerreal/widget",
      binaryMessenger: registrar.messenger()
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "updateSnapshot":
        guard
          let arguments = call.arguments as? [String: Any],
          let defaults = UserDefaults(suiteName: widgetAppGroup),
          let data = try? JSONSerialization.data(withJSONObject: arguments)
        else {
          result(FlutterError(
            code: "BAD_ARGS",
            message: "Missing widget snapshot or app group storage.",
            details: nil
          ))
          return
        }

        defaults.set(data, forKey: widgetSnapshotKey)
        defaults.synchronize()

        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
        }

        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    application.applicationIconBadgeNumber = 0
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
  }
}
