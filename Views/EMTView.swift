//
//  ContentView.swift
//  EMT Times
//
//  Created by Jorge Benjumea on 13/1/25.
//

import SwiftUI
import SwiftData
import CoreLocation

enum SortOrder {
    case nearToFar
    case farToNear
    case alphabetical
}

struct EMTView: View {
    @State private var errorMessage: String?
    @State private var stations: [Station] = []
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var directStopId: String?
    @Query private var favorites: [FavoriteStation]
    @State private var editingStation: FavoriteStation?
    @State private var showingInfo = false
    @Query private var credentials: [Credentials]
    @StateObject private var locationManager = LocationManager()
    @State private var sortOrder: SortOrder = .nearToFar
    @State private var showFavoritesOnly = false
    @State private var showingSortOptions = false
    @State private var showingCredentialsSheet = false
    @State private var isLoading = true
    @State private var isRefreshing = false
    @AppStorage("showDataSourceAlert") private var showDataSourceAlert = false
    @State private var dataSource: String = ""
    @State private var showingDataSourceAlert = false
    @AppStorage("mainView") private var mainView = "list"

    var sortedStations: ([Station], [Station]) {
        var stationsToSort = self.stations.map { station -> Station in
            var mutableStation = station
            if let userLocation = locationManager.location {
                let stationLocation = CLLocation(latitude: station.coordinates.latitude,
                                               longitude: station.coordinates.longitude)
                mutableStation.distance = userLocation.distance(from: stationLocation)
            }
            return mutableStation
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            stationsToSort = stationsToSort.filter { $0.id.contains(searchText) || 
                                                   $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Sort stations
        stationsToSort.sort {
            switch sortOrder {
            case .nearToFar:
                return ($0.distance ?? .infinity) < ($1.distance ?? .infinity)
            case .farToNear:
                return ($0.distance ?? 0) > ($1.distance ?? 0)
            case .alphabetical:
                return $0.name < $1.name
            }
        }
        
        let favoriteIds = Set(favorites.map { $0.stationId })
        let favs = stationsToSort.filter { favoriteIds.contains($0.id) }
        let others = stationsToSort.filter { !favoriteIds.contains($0.id) }
        
        return showFavoritesOnly ? (favs, []) : (favs, others)
    }

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    if mainView == "list" {
                        List {
                            if !sortedStations.0.isEmpty {
                                Section("Favorites") {
                                    ForEach(sortedStations.0) { station in
                                        stationRow(for: station)
                                    }
                                }
                            }
                            if(!showFavoritesOnly){
                                Section("All Stations") {
                                    ForEach(sortedStations.1) { station in
                                        stationRow(for: station)
                                    }
                                }
                            }
                        }
                    } else {
                        MapView(
                            stations: stations,
                            favorites: Set(favorites.map { $0.stationId }),
                            showFavoritesOnly: showFavoritesOnly
                        ) { _ in
                        
                        }
                    }
                }
            }
            .navigationTitle("EMT Stations")
            .navigationBarItems(
                leading: Menu {
                    if(mainView == "list"){
                        Picker("Sort Order", selection: $sortOrder) {
                        Label("Nearest First", systemImage: "location").tag(SortOrder.nearToFar)
                        Label("Farthest First", systemImage: "location.slash").tag(SortOrder.farToNear)
                        Label("Alphabetical", systemImage: "textformat").tag(SortOrder.alphabetical)
                        }
                    } 
                    Picker("View Type", selection: $mainView) {
                        Label("List View", systemImage: "list.bullet").tag("list")
                        Label("Map View", systemImage: "map").tag("map")
                    }.pickerStyle(MenuPickerStyle())
                    Toggle("Show Favorites Only", systemImage: "star", isOn: $showFavoritesOnly)
                    Button(action: {
                        showingCredentialsSheet = true
                    }) {
                        Label("Configure API Credentials", systemImage: "key")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                },
                trailing: Button(action: {
                    showingInfo = true
                }) {
                    Image(systemName: "info.circle")
                }
            )
            .searchable(text: $searchText, placement: .automatic, prompt: "Search by stop number or name")
            .task {
                if credentials.isEmpty {
                    showingCredentialsSheet = true
                }
                // Load cached data first
                if let cached = StationsCache.shared.cachedStations {
                    stations = cached
                    isLoading = false
                    if showDataSourceAlert {
                        dataSource = "Showing data from cache"
                        showingDataSourceAlert = true
                    }
                }
                
                // Check if we need to refresh line information
                if LineCache.shared.shouldRefresh() {
                    await fetchLineInfo()
                }
                
                // Refresh stations in background if needed
                if StationsCache.shared.shouldRefresh() {
                    isRefreshing = true
                    await fetchStations()
                    isRefreshing = false
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .sheet(isPresented: $showingInfo) {
                InfoView(apiStats: TokenManager.shared.getApiStats()) {
                    Task {
                        await fetchStations()
                    }
                }
            }
            .sheet(isPresented: $showingCredentialsSheet) {
                CredentialsView(isPresented: $showingCredentialsSheet)
            }
            .onAppear {
                locationManager.requestLocation()
            }
        }
        .alert("Location Access Required", isPresented: .constant(locationManager.permissionDenied)) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable location access in Settings to see nearby stations.")
        }
        .alert("Data Source", isPresented: $showingDataSourceAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(dataSource)
        }
    }

    @ViewBuilder
    private func stationRow(for station: Station) -> some View {
        StationRowView(station: station)
    }

    private func fetchStations() async {
        isLoading = true
        guard !credentials.isEmpty else {
            showingCredentialsSheet = true
            isLoading = false
            return
        }
        
        guard let credential = credentials.first else {
            errorMessage = "No API credentials found"
            isLoading = false
            return
        }

        
        do {
            let token = try await TokenManager.shared.getToken(using: credential)
            
            let getAllStationURL = URL(string: "https://openapi.emtmadrid.es/v1/transport/busemtmad/stops/list/")!
            var stationsRequest = URLRequest(url: getAllStationURL)
            stationsRequest.httpMethod = "POST"
            stationsRequest.addValue("\(token)", forHTTPHeaderField: "accessToken")
            stationsRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (stationsData, _) = try await URLSession.shared.data(for: stationsRequest)
            let stationsResponse = try JSONDecoder().decode(StationResponse.self, from: stationsData)
            stations = stationsResponse.data

            
            for station in stations {
                print("Station ID: \(station.id), Name: \(station.name), Distance: \(station.distance ?? 0) meters")
            }
            
            // Cache the new data
            StationsCache.shared.saveStations(stationsResponse.data)
            isLoading = false
            if showDataSourceAlert {
                dataSource = "Data freshly downloaded from EMT servers"
                showingDataSourceAlert = true
            }
            
        } catch {
            errorMessage = error.localizedDescription
            print("Error details: \(error)")
            if isLoading && StationsCache.shared.cachedStations != nil {
                // If initial load fails but we have cache, use it
                stations = StationsCache.shared.cachedStations!
                isLoading = false
                if showDataSourceAlert {
                    dataSource = "Showing cached data (download failed due to: \(error.localizedDescription))"
                    showingDataSourceAlert = true
                }
            }
        }
    }

    private func fetchLineInfo() async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        
        guard let credential = credentials.first else { return }
        
        do {
            let token = try await TokenManager.shared.getToken(using: credential)
            
            let url = URL(string: "https://openapi.emtmadrid.es/v2/transport/busemtmad/lines/info/\(dateString)/")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("\(token)", forHTTPHeaderField: "accessToken")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(LineDetailResponse.self, from: data)
            LineCache.shared.saveLines(response.data)
            
        } catch {
            print("Error fetching line info: \(error)")
        }
    }
}

