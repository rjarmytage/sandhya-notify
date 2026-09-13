import Foundation
import Observation

enum LocationMode: String, Codable {
    case automatic
    case manual
}

/// All user-configurable state, backed by UserDefaults so it survives relaunches
/// and background wakes. Per-sandhya toggles default to OFF — the user must
/// actively opt in to each one.
@Observable
final class AppSettings {
    private let defaults: UserDefaults

    var notificationsEnabledGlobally: Bool {
        didSet { defaults.set(notificationsEnabledGlobally, forKey: Keys.notificationsEnabledGlobally) }
    }

    var enabledSandhyas: Set<SandhyaType> {
        didSet {
            defaults.set(enabledSandhyas.map(\.rawValue), forKey: Keys.enabledSandhyas)
        }
    }

    /// Minutes of advance notice before a sandhya window opens. 0 = notify exactly
    /// at window start. Applies globally to all enabled sandhyas.
    var leadTimeMinutes: Int {
        didSet { defaults.set(leadTimeMinutes, forKey: Keys.leadTimeMinutes) }
    }

    var locationMode: LocationMode {
        didSet { defaults.set(locationMode.rawValue, forKey: Keys.locationMode) }
    }

    var manualLocation: SavedLocation? {
        didSet {
            if let manualLocation, let data = try? JSONEncoder().encode(manualLocation) {
                defaults.set(data, forKey: Keys.manualLocation)
            } else {
                defaults.removeObject(forKey: Keys.manualLocation)
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        notificationsEnabledGlobally = defaults.object(forKey: Keys.notificationsEnabledGlobally) as? Bool ?? true

        if let rawValues = defaults.array(forKey: Keys.enabledSandhyas) as? [String] {
            enabledSandhyas = Set(rawValues.compactMap(SandhyaType.init(rawValue:)))
        } else {
            enabledSandhyas = [] // default: all OFF
        }

        leadTimeMinutes = defaults.object(forKey: Keys.leadTimeMinutes) as? Int ?? 10

        locationMode = LocationMode(rawValue: defaults.string(forKey: Keys.locationMode) ?? "") ?? .automatic

        if let data = defaults.data(forKey: Keys.manualLocation) {
            manualLocation = try? JSONDecoder().decode(SavedLocation.self, from: data)
        } else {
            manualLocation = nil
        }
    }

    func isEnabled(_ type: SandhyaType) -> Bool {
        enabledSandhyas.contains(type)
    }

    func setEnabled(_ enabled: Bool, for type: SandhyaType) {
        if enabled {
            enabledSandhyas.insert(type)
        } else {
            enabledSandhyas.remove(type)
        }
    }

    private enum Keys {
        static let notificationsEnabledGlobally = "notificationsEnabledGlobally"
        static let enabledSandhyas = "enabledSandhyas"
        static let leadTimeMinutes = "leadTimeMinutes"
        static let locationMode = "locationMode"
        static let manualLocation = "manualLocation"
    }
}
