import Foundation

/// Today's three sandhya windows, plus enough of tomorrow's to know what's next
/// if today's have all already passed (e.g. late at night).
struct DailySandhyaSchedule {
    let today: [SandhyaWindow]
    /// Chronologically sorted union of today's and tomorrow's windows, used only
    /// to find the current/next window across a midnight boundary.
    let extended: [SandhyaWindow]

    static func compute(location: SavedLocation, now: Date) -> DailySandhyaSchedule {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = location.timeZone

        let todaySolar = SolarCalculator.solarTimes(
            for: now, latitude: location.latitude, longitude: location.longitude, timeZone: location.timeZone
        )
        let todayWindows = SandhyaCalculator.windows(for: todaySolar)

        var extended = todayWindows
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
            let tomorrowSolar = SolarCalculator.solarTimes(
                for: tomorrow, latitude: location.latitude, longitude: location.longitude, timeZone: location.timeZone
            )
            extended += SandhyaCalculator.windows(for: tomorrowSolar)
        }
        extended.sort { $0.start < $1.start }

        return DailySandhyaSchedule(today: todayWindows, extended: extended)
    }

    /// The window happening right now, if any.
    func currentWindow(at date: Date) -> SandhyaWindow? {
        extended.first { $0.contains(date) }
    }

    /// The next window to start, if we're not currently inside one.
    func nextWindow(at date: Date) -> SandhyaWindow? {
        extended.first { $0.start > date }
    }
}
