import SwiftUI
import MapKit

struct MapView: View {
    let stations: [Station]
    let favorites: Set<String>
    let showFavoritesOnly: Bool
    var onStationSelected: (Station) -> Void
    @State private var selectedStation: Station?
    @State private var position: MapCameraPosition
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var hasInitialLocation = false
    @State private var selectedStopId: String?
    @State private var selectedCoordinates: CLLocationCoordinate2D?
    
    init(stations: [Station], favorites: Set<String>, showFavoritesOnly: Bool = false, onStationSelected: @escaping (Station) -> Void) {
        self.stations = stations
        self.favorites = favorites
        self.showFavoritesOnly = showFavoritesOnly
        self.onStationSelected = onStationSelected
        
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )))
    }
    
    var visibleStations: [Station] {
        guard let region = visibleRegion, hasInitialLocation else { return [] }
        let filtered = stations.filter { station in
            region.contains(coordinate: station.coordinates)
        }
        return showFavoritesOnly ? filtered.filter { favorites.contains($0.id) } : filtered
    }

    private var stationBinding: Binding<Station?> {
        Binding(
            get: { selectedStation },
            set: { newValue in
                selectedStation = newValue
                if newValue == nil {
                    selectedStopId = nil
                    selectedCoordinates = nil
                }
            }
        )
    }

    var body: some View {
        ZStack {
            Map(initialPosition: position, selection: stationBinding) {
                if hasInitialLocation {
                    UserAnnotation()
                    ForEach(visibleStations) { station in
                        Marker(station.name, systemImage: favorites.contains(station.id) ? "star.fill" : "mappin", 
                              coordinate: station.coordinates)
                        .tint(favorites.contains(station.id) ? .yellow : .red)
                        .tag(station)
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .onMapCameraChange { context in
                visibleRegion = context.region
            }
            .onChange(of: selectedStation) { _, station in
                if let station = station {
                    selectedStopId = station.id
                    selectedCoordinates = station.coordinates
                }
            }
            .onTapGesture { _ in }
            
            NavigationLink(
                destination: Group {
                    if let stopId = selectedStopId,
                       let coordinates = selectedCoordinates {
                        StopDetailView(stopId: stopId, stationCoordinates: coordinates)
                            .onDisappear {
                                selectedStation = nil
                            }
                    }
                },
                isActive: .init(
                    get: { selectedStopId != nil },
                    set: { if !$0 { 
                        selectedStopId = nil
                        selectedCoordinates = nil
                        selectedStation = nil
                    } }
                )
            ) { EmptyView() }
        }
        .task {
            if let location = await LocationManager.shared.requestLocation() {
                position = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) 
                ))
                hasInitialLocation = true
            }
        }
    }
    
    private func handleStationSelection(_ station: Station) {
        selectedStation = station
        selectedStopId = station.id
        selectedCoordinates = station.coordinates
    }
}

extension MKCoordinateRegion {
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        let latDelta = self.span.latitudeDelta / 2.0
        let lngDelta = self.span.longitudeDelta / 2.0
        
        return (coordinate.latitude >= self.center.latitude - latDelta &&
                coordinate.latitude <= self.center.latitude + latDelta &&
                coordinate.longitude >= self.center.longitude - lngDelta &&
                coordinate.longitude <= self.center.longitude + lngDelta)
    }
}
