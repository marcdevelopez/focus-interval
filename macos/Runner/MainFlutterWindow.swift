import Cocoa
import FlutterMacOS
import UserNotifications

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(
      name: "focus_interval/macos_notifications",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "requestPermission":
        UNUserNotificationCenter.current().requestAuthorization(
          options: [.alert, .sound, .badge]
        ) { granted, error in
          DispatchQueue.main.async {
            if let error = error {
              result(FlutterError(
                code: "permission_error",
                message: error.localizedDescription,
                details: nil
              ))
            } else {
              result(granted)
            }
          }
        }
      case "showNotification":
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(
            code: "invalid_args",
            message: "Missing notification arguments.",
            details: nil
          ))
          return
        }
        let title = args["title"] as? String ?? "Focus Interval"
        let body = args["body"] as? String ?? ""
        let content = UNMutableNotificationContent()
        content.title = title
        if !body.isEmpty {
          content.body = body
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
          identifier: UUID().uuidString,
          content: content,
          trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
          DispatchQueue.main.async {
            if let error = error {
              result(FlutterError(
                code: "notification_error",
                message: error.localizedDescription,
                details: nil
              ))
            } else {
              result(true)
            }
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}
