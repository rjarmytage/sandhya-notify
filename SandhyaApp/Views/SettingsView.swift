import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss
    @State private var showingLocationPicker = false

    private static let leadTimeOptions = Array(0...59)

    var body: some View {
        @Bindable var settings = coordinator.settings

        NavigationStack {
            Form {
                Section {
                    Toggle("Notifications", isOn: $settings.notificationsEnabledGlobally)
                        .onChange(of: settings.notificationsEnabledGlobally) { _, _ in coordinator.settingsDidChange() }
                } footer: {
                    Text("Turns all sandhya notifications on or off at once.")
                }

                Section {
                    ForEach(SandhyaType.allCases) { type in
                        Toggle(isOn: Binding(
                            get: { coordinator.settings.isEnabled(type) },
                            set: { newValue in
                                coordinator.settings.setEnabled(newValue, for: type)
                                coordinator.settingsDidChange()
                            }
                        )) {
                            VStack(alignment: .leading) {
                                Text(type.displayName)
                                Text(type.shortDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Sandhyas")
                } footer: {
                    Text("Each is off by default. Windows are fixed at 72 minutes (scriptural ghati durations) and aren't adjustable.")
                }

                Section {
                    Picker(selection: $settings.leadTimeMinutes) {
                        ForEach(Self.leadTimeOptions, id: \.self) { minutes in
                            Text(minutes == 0 ? "At start" : "\(minutes) min")
                                .tag(minutes)
                        }
                    } label: {
                        EmptyView()
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 110)
                    .clipped()
                    .onChange(of: settings.leadTimeMinutes) { _, _ in coordinator.settingsDidChange() }
                } header: {
                    Text("Advance Notice")
                } footer: {
                    Text("How far ahead of a sandhya window's start you'd like to be notified.")
                }

                Section {
                    Picker("Location Mode", selection: Binding(
                        get: { coordinator.settings.locationMode },
                        set: { newMode in
                            if newMode == .automatic {
                                coordinator.switchToAutomatic()
                            } else if let manual = coordinator.settings.manualLocation {
                                coordinator.switchToManual(manual)
                            } else {
                                showingLocationPicker = true
                            }
                        }
                    )) {
                        Text("Automatic (this device)").tag(LocationMode.automatic)
                        Text("Manual").tag(LocationMode.manual)
                    }
                    .pickerStyle(.segmented)

                    if coordinator.settings.locationMode == .automatic {
                        automaticLocationStatus
                    } else {
                        Button {
                            showingLocationPicker = true
                        } label: {
                            HStack {
                                Text("Chosen Location")
                                Spacer()
                                Text(coordinator.settings.manualLocation?.name ?? "Choose…")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Location")
                } footer: {
                    Text("Used only to calculate local sunrise, sunset, and solar noon. Never stored remotely or used for tracking.")
                }

                Section {
                    Toggle("Dark Mode", isOn: $settings.forceDarkMode)
                } footer: {
                    Text("Off follows your device's system appearance. On always uses dark mode.")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView { location in
                    coordinator.switchToManual(location)
                }
            }
        }
    }

    @ViewBuilder
    private var automaticLocationStatus: some View {
        switch coordinator.locationManager.authorizationStatus {
        case .authorizedAlways:
            Label("Background updates active", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .authorizedWhenInUse:
            VStack(alignment: .leading, spacing: 4) {
                Label("Limited to foreground only", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Grant \"Always\" access so times keep updating automatically while the app is closed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Grant Always Access") {
                    coordinator.locationManager.requestAlwaysAuthorization()
                }
            }
        case .denied, .restricted:
            VStack(alignment: .leading, spacing: 4) {
                Label("Location access denied", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text("Enable location access in the Settings app, or switch to Manual mode above.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Open Settings App") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        default:
            Button("Grant Location Access") {
                coordinator.locationManager.requestAlwaysAuthorization()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppCoordinator())
}
