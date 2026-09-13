import Foundation

/// One Ghati = 24 minutes, the traditional unit these windows are scripturally defined in.
enum Ghati {
    static let minutes: Double = 24
}

enum SandhyaType: String, CaseIterable, Identifiable, Codable {
    case pratah
    case madhyahna
    case sayam

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pratah: return "Pratah Sandhya"
        case .madhyahna: return "Madhyahna Sandhya"
        case .sayam: return "Sayam Sandhya"
        }
    }

    var shortDescription: String {
        switch self {
        case .pratah: return "Dawn"
        case .madhyahna: return "Midday"
        case .sayam: return "Dusk"
        }
    }

    /// Minutes before the anchor solar event that the window opens. Fixed, not user-configurable.
    var minutesBeforeAnchor: Double {
        switch self {
        case .pratah: return 2 * Ghati.minutes      // 48 min before sunrise
        case .madhyahna: return 1.5 * Ghati.minutes // 36 min before solar noon
        case .sayam: return 1 * Ghati.minutes       // 24 min before sunset
        }
    }

    /// Minutes after the anchor solar event that the window closes. Fixed, not user-configurable.
    var minutesAfterAnchor: Double {
        switch self {
        case .pratah: return 1 * Ghati.minutes      // 24 min after sunrise
        case .madhyahna: return 1.5 * Ghati.minutes // 36 min after solar noon
        case .sayam: return 2 * Ghati.minutes       // 48 min after sunset
        }
    }

    var totalDurationMinutes: Double { minutesBeforeAnchor + minutesAfterAnchor }
}

/// A concrete, dated window for one sandhya, anchored to that day's actual solar event.
struct SandhyaWindow: Identifiable {
    let type: SandhyaType
    let anchor: Date
    let start: Date
    let end: Date

    var id: String { "\(type.rawValue)-\(anchor.timeIntervalSince1970)" }

    func contains(_ date: Date) -> Bool {
        date >= start && date <= end
    }
}

enum SandhyaCalculator {
    /// Builds today's three sandhya windows from a day's solar times. A window is
    /// omitted only if its anchor solar event doesn't occur that day (polar sunrise/sunset).
    static func windows(for solarTimes: SolarTimes) -> [SandhyaWindow] {
        var results: [SandhyaWindow] = []

        if let sunrise = solarTimes.sunrise {
            results.append(window(for: .pratah, anchor: sunrise))
        }
        results.append(window(for: .madhyahna, anchor: solarTimes.solarNoon))
        if let sunset = solarTimes.sunset {
            results.append(window(for: .sayam, anchor: sunset))
        }

        return results
    }

    private static func window(for type: SandhyaType, anchor: Date) -> SandhyaWindow {
        SandhyaWindow(
            type: type,
            anchor: anchor,
            start: anchor.addingTimeInterval(-type.minutesBeforeAnchor * 60),
            end: anchor.addingTimeInterval(type.minutesAfterAnchor * 60)
        )
    }
}
