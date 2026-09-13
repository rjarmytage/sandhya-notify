import BackgroundTasks
import SwiftUI

@main
struct SandhyaApp: App {
    static let backgroundRefreshTaskIdentifier = "com.armytage.sandhya.refresh"

    @State private var coordinator = AppCoordinator()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(coordinator)
                .preferredColorScheme(coordinator.settings.forceDarkMode ? .dark : nil)
                .task {
                    _ = await NotificationScheduler.requestAuthorizationIfNeeded()
                    coordinator.start()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                scheduleBackgroundRefresh()
            }
        }
        .backgroundTask(.appRefresh(Self.backgroundRefreshTaskIdentifier)) {
            await handleBackgroundRefresh()
        }
    }

    /// Recomputes solar times and reschedules notifications from the background,
    /// so the app stays accurate even if the user doesn't open it every day. Also
    /// re-arms itself so refreshes keep happening periodically.
    private func handleBackgroundRefresh() async {
        await coordinator.refreshAndReschedule()
        scheduleBackgroundRefresh()
    }

    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundRefreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 12 * 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}
