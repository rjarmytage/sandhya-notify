import CoreLocation
import MapKit
import Observation

/// Backs the manual-location picker's search field: turns typed text into
/// place suggestions, and a chosen suggestion (or a map tap) into a `SavedLocation`
/// with a resolved time zone.
@Observable
final class LocationSearchService: NSObject, MKLocalSearchCompleterDelegate {
    private let completer = MKLocalSearchCompleter()
    private let geocoder = CLGeocoder()

    private(set) var results: [MKLocalSearchCompletion] = []

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func updateQuery(_ query: String) {
        completer.queryFragment = query
    }

    func resolve(_ completion: MKLocalSearchCompletion) async -> SavedLocation? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        guard let response = try? await search.start(), let item = response.mapItems.first else {
            return nil
        }
        let coordinate = item.placemark.coordinate
        let name = item.name ?? completion.title
        var timeZoneIdentifier = item.timeZone?.identifier
        if timeZoneIdentifier == nil {
            timeZoneIdentifier = await reverseGeocodedTimeZone(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        let resolvedTimeZoneIdentifier = timeZoneIdentifier ?? TimeZone.current.identifier
        return SavedLocation(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timeZoneIdentifier: resolvedTimeZoneIdentifier
        )
    }

    /// Resolves a raw map-tap coordinate into a named, time-zoned location.
    func resolve(coordinate: CLLocationCoordinate2D) async -> SavedLocation? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first else {
            return SavedLocation(
                name: String(format: "%.3f, %.3f", coordinate.latitude, coordinate.longitude),
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                timeZoneIdentifier: TimeZone.current.identifier
            )
        }
        let name = [placemark.locality, placemark.administrativeArea, placemark.country]
            .compactMap { $0 }
            .joined(separator: ", ")
        return SavedLocation(
            name: name.isEmpty ? String(format: "%.3f, %.3f", coordinate.latitude, coordinate.longitude) : name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timeZoneIdentifier: placemark.timeZone?.identifier ?? TimeZone.current.identifier
        )
    }

    private func reverseGeocodedTimeZone(latitude: Double, longitude: Double) async -> String? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let placemark = try? await geocoder.reverseGeocodeLocation(location).first
        return placemark?.timeZone?.identifier
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}
