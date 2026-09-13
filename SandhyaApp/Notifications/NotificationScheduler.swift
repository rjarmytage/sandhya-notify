import Foundation
import UserNotifications

/// Schedules and refreshes local notifications for the three sandhyas. Entirely
/// on-device: no push, no server. Notifications are scheduled several days ahead
/// so the app doesn't need to wake every single day to keep working, and are
/// fully re-derived (old ones cancelled, new ones scheduled) on every call, so
/// it's always safe to call this again after a settings or location change.
enum NotificationScheduler {
    /// How many days ahead to keep notifications scheduled. Comfortably under
    /// the 64-pending-notification system limit even with all three sandhyas on
    /// (3 x 7 = 21).
    static let daysAhead = 7

    private static let identifierPrefix = "sandhya-"

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    /// Recomputes solar times for the next `daysAhead` days at the given location
    /// and replaces all pending sandhya notifications with freshly scheduled ones.
    static func rescheduleAll(settings: AppSettings, location: SavedLocation, now: Date = Date()) async {
        let center = UNUserNotificationCenter.current()

        let pending = await center.pendingNotificationRequests()
        let ourIdentifiers = pending.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ourIdentifiers)

        guard settings.notificationsEnabledGlobally, !settings.enabledSandhyas.isEmpty else { return }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = location.timeZone

        var requests: [UNNotificationRequest] = []

        for dayOffset in 0..<daysAhead {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let solarTimes = SolarCalculator.solarTimes(
                for: day,
                latitude: location.latitude,
                longitude: location.longitude,
                timeZone: location.timeZone
            )
            let windows = SandhyaCalculator.windows(for: solarTimes)

            for window in windows where settings.enabledSandhyas.contains(window.type) {
                let notifyDate = window.start.addingTimeInterval(-Double(settings.leadTimeMinutes) * 60)
                guard notifyDate > now else { continue }

                let components = calendar.dateComponents(in: location.timeZone, from: notifyDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

                let request = UNNotificationRequest(
                    identifier: identifierPrefix + window.id,
                    content: makeContent(for: window.type, leadTimeMinutes: settings.leadTimeMinutes),
                    trigger: trigger
                )
                requests.append(request)
            }
        }

        for request in requests {
            try? await center.add(request)
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private static func makeContent(for type: SandhyaType, leadTimeMinutes: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = type.displayName
        content.sound = .default

        let durationText = "The window lasts about 1 hour 12 minutes."
        if leadTimeMinutes > 0 {
            let unit = leadTimeMinutes == 1 ? "minute" : "minutes"
            content.body = "\(type.displayName) begins in \(leadTimeMinutes) \(unit). \(durationText)"
        } else {
            content.body = "\(type.displayName) has begun. \(durationText)"
        }
        return content
    }
}
