import SwiftUI

struct HomeView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if let location = coordinator.effectiveLocation {
                    TimelineView(.everyMinute) { context in
                        let schedule = DailySandhyaSchedule.compute(location: location, now: context.date)
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                statusBanner(schedule: schedule, now: context.date)

                                VStack(spacing: 12) {
                                    ForEach(schedule.today) { window in
                                        SandhyaRowView(window: window, isCurrent: window.contains(context.date))
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("Waiting for Location", systemImage: "location.slash")
                    } description: {
                        Text(coordinator.locationManager.isDeniedOrRestricted
                             ? "Location access is denied. Pick a location manually in Settings, or grant access in the Settings app."
                             : "Grant location access, or choose a location manually in Settings, to see today's sandhya times.")
                    } actions: {
                        Button("Open Settings") { showingSettings = true }
                    }
                    .padding()
                }
            }
            .navigationTitle("Sandhya Notify")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Sandhya Notify")
                        .font(.system(size: 28, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let location = coordinator.effectiveLocation {
                    HStack(spacing: 6) {
                        Image(systemName: coordinator.settings.locationMode == .automatic ? "location.fill" : "mappin.circle.fill")
                            .foregroundStyle(.secondary)
                        Text(location.name)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        if coordinator.isResolvingLocation {
                            ProgressView().controlSize(.mini)
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(.bar)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    @ViewBuilder
    private func statusBanner(schedule: DailySandhyaSchedule, now: Date) -> some View {
        if let current = schedule.currentWindow(at: now) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Now")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(current.type.displayName)
                    .font(.title2.bold())
                Text("Until \(current.end.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
        } else if let next = schedule.nextWindow(at: now) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Next")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(next.type.displayName)
                    .font(.title2.bold())
                Text(next.start.formatted(date: isToday(next.start) ? .omitted : .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

private struct SandhyaRowView: View {
    let window: SandhyaWindow
    let isCurrent: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(window.type.displayName)
                    .font(.headline)
                Text(window.type.shortDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(window.start.formatted(date: .omitted, time: .shortened)) – \(window.end.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline.monospacedDigit())
                Text("anchor \(window.anchor.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(isCurrent ? Color.accentColor.opacity(0.12) : Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            if isCurrent {
                RoundedRectangle(cornerRadius: 14).strokeBorder(Color.accentColor, lineWidth: 1.5)
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(AppCoordinator())
}
