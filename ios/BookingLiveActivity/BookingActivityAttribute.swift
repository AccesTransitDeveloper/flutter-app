import ActivityKit
import Foundation

struct BookingLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var bookingId: String
        var uniqueId: String
        var progress: Int
        var pickupPoint: [Int]
        var destinationPoint: Int
        var carInfo: CarInfo
        var driverInfo: DriverInfo
        var status: Int
        var timestamp: Int64
    }

    public struct CarInfo: Codable, Hashable {
        var name: String
        var plate: String
    }

    public struct DriverInfo: Codable, Hashable {
        var name: String
        var photoUrl: String
    }

    public var bookingId: String
    // Resolve the visible app name from the bundle (the attribute is created in
    // the main app, so Bundle.main is the app, not the widget extension). Using
    // the display name keeps this white-label friendly instead of relying on a
    // missing "app_name" localization key.
    var strAppName: String = (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
        ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
        ?? "AT"

    // Rich, ride-static details. These live on the (immutable) attributes rather
    // than ContentState so a backend ContentState push — which only carries
    // progress/status — never wipes them. Set once when the activity starts.
    var driverName: String = ""
    var rating: String = ""
    var vehicleName: String = ""
    var plateNo: String = ""
    var pickupAddress: String = ""
    var destinationAddress: String = ""
    var pickupTime: String = ""
    var destinationTime: String = ""
    // Absolute path to a driver photo in the shared App Group container. Empty
    // (or unreadable, e.g. before the App Group capability is enabled) → the
    // widget falls back to a placeholder avatar.
    var photoPath: String = ""

    init(
        bookingId: String,
        driverName: String = "",
        rating: String = "",
        vehicleName: String = "",
        plateNo: String = "",
        pickupAddress: String = "",
        destinationAddress: String = "",
        pickupTime: String = "",
        destinationTime: String = "",
        photoPath: String = ""
    ) {
        self.bookingId = bookingId
        self.driverName = driverName
        self.rating = rating
        self.vehicleName = vehicleName
        self.plateNo = plateNo
        self.pickupAddress = pickupAddress
        self.destinationAddress = destinationAddress
        self.pickupTime = pickupTime
        self.destinationTime = destinationTime
        self.photoPath = photoPath
    }
}
