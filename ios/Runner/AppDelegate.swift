import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate, MessagingDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("🚀 [AppDelegate] Application did finish launching")

        FirebaseApp.configure()
        print("🔥 Firebase configured")

        GeneratedPluginRegistrant.register(with: self)

        // Register for remote notifications
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self

        print("🔔 Push notification setup complete")
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Called when APNs registration succeeds
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("✅ [APNs] Device token registered: \(tokenString)")

        Messaging.messaging().apnsToken = deviceToken
    }

    // Called when FCM registration token is received or refreshed
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("📱 [FCM] Registration token received: \(fcmToken ?? "nil")")
    }

    // Handles notification when app is in foreground
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("📡 [Foreground Notification] Payload: \(userInfo)")

        Messaging.messaging().appDidReceiveMessage(userInfo)

        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    // Handles silent/background push or app terminated push
    override func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📩 [Background/Silent Push] Payload received: \(userInfo)")

        if let aps = userInfo["aps"] as? [String: Any] {
            if aps["content-available"] as? Int == 1 {
                print("🕵️‍♂️ [Silent Push] Confirmed: content-available = 1")
            } else {
                print("⚠️ [Silent Push] Missing or invalid content-available flag")
            }
        } else {
            print("⚠️ [Silent Push] No aps dictionary found")
        }

        Messaging.messaging().appDidReceiveMessage(userInfo)
        completionHandler(.newData)
    }
}
