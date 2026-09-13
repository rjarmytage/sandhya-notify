import CoreLocation
import Foundation
import Observation

/// Ties together settings, location, and notification scheduling. Views read
/// `effectiveLocation` / `todaySolarTimes` for display; changes to settings or
/// location flow through here so notifications stay in sync automatically.
@Observable
final class AppCoordinator {
    let settings = AppSettings()
    let locationManager = LocationManager()
    private let searchService = LocationSearchService()

    private(set) var effectiveLocation: SavedLocation?
    private(set) var isResolvingLocation = false
    private(set) var lastRefreshDate: Date?

    init() {
        locationManager.onLocationChanged = { [weak self] location in
            Task { await self?.handleGPSLocationUpdate(location) }
        }
    }

    func start() {
        switch settings.locationMode {
        case .automatic:
            locationManager.startMonitoringIfAuthorized()
        case .manual:
            effectiveLocation = settings.manualLocation
        }
        Task { await refreshAndReschedule() }
    }

    /// Call whenever a setting changes (toggles, lead time, etc.) so notifications
    /// are recomputed against the latest preferences.
    func settingsDidChange() {
        Task { await refreshAndReschedule() }
    }

    func switchToAutomatic() {
        settings.locationMode = .automatic
        locationManager.requestAlwaysAuthorization()
        locationManager.startMonitoringIfAuthorized()
        Task { await refreshAndReschedule() }
    }

    func switchToManual(_ location: SavedLocation) {
        settings.locationMode = .manual
        settings.manualLocation = location
        locationManager.stopMonitoring()
        effectiveLocation = location
        Task { await refreshAndReschedule() }
    }

    /// Re-derives the effective location (if needed) and reschedules all
    /// notifications against it. Safe to call as often as needed.
    func refreshAndReschedule() async {
        switch settings.locationMode {
        case .manual:
            guard let manual = settings.manualLocation else { return }
            effectiveLocation = manual
            await NotificationScheduler.rescheduleAll(settings: settings, location: manual)

        case .automatic:
            guard let current = locationManager.currentLocation else { return }
            isResolvingLocation = true
            let resolved = await searchService.resolve(coordinate: current.coordinate)
            isResolvingLocation = false
            guard let resolved else { return }
            effectiveLocation = resolved
            await NotificationScheduler.rescheduleAll(settings: settings, location: resolved)
        }
        lastRefreshDate = Date()
    }

    private func handleGPSLocationUpdate(_ location: CLLocation) async {
        guard settings.locationMode == .automatic else { return }
        isResolvingLocation = true
        let resolved = await searchService.resolve(coordinate: location.coordinate)
        isResolvingLocation = false
        guard let resolved else { return }
        effectiveLocation = resolved
        await NotificationScheduler.rescheduleAll(settings: settings, location: resolved)
        lastRefreshDate = Date()
    }
}
