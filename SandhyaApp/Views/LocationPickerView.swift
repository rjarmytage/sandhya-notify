import CoreLocation
import MapKit
import SwiftUI

struct LocationPickerView: View {
    var onSelect: (SavedLocation) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchService = LocationSearchService()
    @State private var queryText = ""
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var isResolving = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !queryText.isEmpty {
                    List {
                        ForEach(searchService.results.indices, id: \.self) { index in
                            let completion = searchService.results[index]
                            Button {
                                Task { await selectCompletion(completion) }
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(completion.title)
                                    if !completion.subtitle.isEmpty {
                                        Text(completion.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                } else {
                    MapReader { proxy in
                        Map(position: $cameraPosition)
                            .onTapGesture(coordinateSpace: .local) { screenPoint in
                                if let coordinate = proxy.convert(screenPoint, from: .local) {
                                    Task { await selectCoordinate(coordinate) }
                                }
                            }
                    }
                    .overlay {
                        if isResolving {
                            ProgressView()
                                .padding()
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .safeAreaInset(edge: .bottom) {
                        Text("Tap the map to drop a pin, or search above for a city or landmark.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(.bar)
                    }
                }
            }
            .searchable(text: $queryText, prompt: "Search city or place")
            .onChange(of: queryText) { _, newValue in searchService.updateQuery(newValue) }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func selectCompletion(_ completion: MKLocalSearchCompletion) async {
        isResolving = true
        defer { isResolving = false }
        if let location = await searchService.resolve(completion) {
            onSelect(location)
            dismiss()
        }
    }

    private func selectCoordinate(_ coordinate: CLLocationCoordinate2D) async {
        isResolving = true
        defer { isResolving = false }
        if let location = await searchService.resolve(coordinate: coordinate) {
            onSelect(location)
            dismiss()
        }
    }
}

#Preview {
    LocationPickerView { _ in }
}
