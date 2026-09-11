import Flutter
import UIKit
import GoogleMaps
import FirebaseCore
import FirebaseMessaging
import ActivityKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var liveActivityChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    guard let mapsAPIKey = Bundle.main.object(
      forInfoDictionaryKey: "GoogleMapsAPIKey"
    ) as? String, !mapsAPIKey.isEmpty else {
      fatalError("GOOGLE_MAPS_API_KEY is missing from ios/Flutter/Secrets.xcconfig")
    }
    GMSServices.provideAPIKey(mapsAPIKey)
    GeneratedPluginRegistrant.register(with: self)

    Messaging.messaging().delegate = self
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    UIApplication.shared.applicationIconBadgeNumber = 0

    // Setup Live Activity platform channel
    if let controller = window?.rootViewController as? FlutterViewController {
      liveActivityChannel = FlutterMethodChannel(
        name: "com.accessible.customer/live_activity",
        binaryMessenger: controller.binaryMessenger
      )
      liveActivityChannel?.setMethodCallHandler(handleLiveActivityMethod)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Pass APNS token to Firebase
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Forward remote notifications to Firebase
  override func application(_ application: UIApplication,
                            didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                            fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    Messaging.messaging().appDidReceiveMessage(userInfo)
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }

  // MARK: - Live Activity Platform Channel Handler
  private func handleLiveActivityMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.1, *) else {
      result(FlutterError(code: "UNSUPPORTED", message: "Live Activities require iOS 16.1+", details: nil))
      return
    }

    switch call.method {
    case "startActivity":
      guard let args = call.arguments as? [String: Any],
            let bookingId = args["bookingId"] as? String,
            let uniqueId = args["uniqueId"] as? String,
            let status = args["status"] as? Int,
            let progress = args["progress"] as? Int,
            let pickupPoints = args["pickupPoints"] as? [Int],
            let destinationPoint = args["destinationPoint"] as? Int else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
        return
      }
      startLiveActivity(
        bookingId: bookingId,
        uniqueId: uniqueId,
        status: status,
        progress: progress,
        pickupPoints: pickupPoints,
        destinationPoint: destinationPoint,
        driverName: args["driverName"] as? String ?? "",
        rating: args["rating"] as? String ?? "",
        vehicleName: args["vehicleName"] as? String ?? "",
        plateNo: args["plateNo"] as? String ?? "",
        pickupAddress: args["pickupAddress"] as? String ?? "",
        destinationAddress: args["destinationAddress"] as? String ?? "",
        pickupTime: args["pickupTime"] as? String ?? "",
        destinationTime: args["destinationTime"] as? String ?? "",
        photoPath: args["photoPath"] as? String ?? "",
        result: result
      )

    case "stopActivity":
      guard let args = call.arguments as? [String: Any],
            let bookingId = args["bookingId"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing bookingId", details: nil))
        return
      }
      stopLiveActivity(bookingId: bookingId, result: result)

    case "stopAllActivities":
      stopAllLiveActivities(result: result)

    case "isActivityActive":
      guard let args = call.arguments as? [String: Any],
            let bookingId = args["bookingId"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing bookingId", details: nil))
        return
      }
      result(isActivityActive(bookingId: bookingId))

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Live Activity Management
  @available(iOS 16.1, *)
  private func startLiveActivity(
    bookingId: String,
    uniqueId: String,
    status: Int,
    progress: Int,
    pickupPoints: [Int],
    destinationPoint: Int,
    driverName: String,
    rating: String,
    vehicleName: String,
    plateNo: String,
    pickupAddress: String,
    destinationAddress: String,
    pickupTime: String,
    destinationTime: String,
    photoPath: String,
    result: @escaping FlutterResult
  ) {
    // Don't start if already exists
    for activity in Activity<BookingLiveActivityAttributes>.activities where activity.attributes.bookingId == bookingId {
      result(true) // Already active
      return
    }

    let attributes = BookingLiveActivityAttributes(
      bookingId: bookingId,
      driverName: driverName,
      rating: rating,
      vehicleName: vehicleName,
      plateNo: plateNo,
      pickupAddress: pickupAddress,
      destinationAddress: destinationAddress,
      pickupTime: pickupTime,
      destinationTime: destinationTime,
      photoPath: photoPath
    )
    let initialState = BookingLiveActivityAttributes.ContentState(
      bookingId: bookingId,
      uniqueId: uniqueId,
      progress: progress,
      pickupPoint: pickupPoints,
      destinationPoint: destinationPoint,
      carInfo: .init(name: "", plate: ""),
      driverInfo: .init(name: "", photoUrl: ""),
      status: status,
      timestamp: 0
    )

    do {
      let activity = try Activity<BookingLiveActivityAttributes>.request(
        attributes: attributes,
        contentState: initialState,
        pushType: .token
      )

      // Listen for push token updates and send back to Flutter
      Task {
        for await pushToken in activity.pushTokenUpdates where activity.attributes.bookingId == bookingId {
          let pushTokenString = pushToken.map { String(format: "%02x", $0) }.joined()
          DispatchQueue.main.async {
            self.liveActivityChannel?.invokeMethod("onPushTokenUpdated", arguments: [
              "bookingId": bookingId,
              "token": pushTokenString
            ])
          }
        }
      }

      result(true)
    } catch {
      print("Failed to start Live Activity: \(error.localizedDescription)")
      result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
    }
  }

  @available(iOS 16.1, *)
  private func stopLiveActivity(bookingId: String, result: @escaping FlutterResult) {
    for activity in Activity<BookingLiveActivityAttributes>.activities where activity.attributes.bookingId == bookingId {
      Task {
        await activity.end(dismissalPolicy: .immediate)
      }
    }
    result(true)
  }

  @available(iOS 16.1, *)
  private func stopAllLiveActivities(result: @escaping FlutterResult) {
    for activity in Activity<BookingLiveActivityAttributes>.activities {
      Task {
        await activity.end(dismissalPolicy: .immediate)
      }
    }
    result(true)
  }

  @available(iOS 16.1, *)
  private func isActivityActive(bookingId: String) -> Bool {
    return Activity<BookingLiveActivityAttributes>.activities.contains { $0.attributes.bookingId == bookingId }
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔔 FCM Token: \(fcmToken ?? "nil")")
  }
}
