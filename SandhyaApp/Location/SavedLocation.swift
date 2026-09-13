import Foundation

/// A user-picked or device-detected place, with enough information to compute
/// solar times without needing to re-resolve a time zone at calculation time.
struct SavedLocation: Codable, Equatable {
    var name: String
    var latitude: Double
    var longitude: Double
    var timeZoneIdentifier: String

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }
}
