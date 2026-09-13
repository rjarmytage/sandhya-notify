import CoreLocation
import Observation

/// Wraps CoreLocation's significant-change location service — the low-power API
/// meant for exactly this "notice when the user has moved to a new city/region"
/// use case, as opposed to continuous GPS tracking. Only active while the app is
/// in automatic (GPS-based) location mode.
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var currentLocation: CLLocation?

    /// Called whenever the significant-change service reports a new location,
    /// so callers can recompute solar times and reschedule notifications.
    var onLocationChanged: ((CLLocation) -> Void)?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    var isAuthorizedAlways: Bool {
        authorizationStatus == .authorizedAlways
    }

    var isDeniedOrRestricted: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func requestAlwaysAuthorization() {
        // Apple requires requesting "When In Use" first; the system then offers
        // an upgrade path to "Always" (either immediately via a follow-up prompt
        // depending on iOS version, or later via a subtle in-app request once the
        // when-in-use grant has been used for a bit).
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        default:
            break
        }
    }

    /// Starts significant-change monitoring. Safe to call repeatedly; CoreLocation
    /// no-ops if already monitoring. Requires "Always" authorization to keep
    /// delivering updates while the app is not in the foreground.
    func startMonitoringIfAuthorized() {
        guard CLLocationManager.significantLocationChangeMonitoringAvailable() else { return }
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else { return }
        manager.startMonitoringSignificantLocationChanges()
        // Kick off an immediate one-shot fix too, so the app has a location the
        // very first time it's authorized rather than waiting for the next
        // "significant" move (which could be many miles / a while away).
        manager.requestLocation()
    }

    func stopMonitoring() {
        manager.stopMonitoringSignificantLocationChanges()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            startMonitoringIfAuthorized()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        onLocationChanged?(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Significant-change monitoring is resilient and will keep trying; nothing
        // actionable to do here beyond leaving the last known location in place.
    }
}
