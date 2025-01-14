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

struct ContentView: View {
    @State private var errorMessage: String?
    @State private var stations: [Station] = []
    @Environment(\.modelContext) private var modelContext
    @State private var useMockData = false
    @State private var searchText = ""
    @State private var directStopId: String?
    @Query private var favorites: [FavoriteStation]
    @State private var editingStation: FavoriteStation?
    @State private var showingNameEditor = false
    @State private var tempCustomName = ""
    @State private var showingInfo = false
    @Query private var credentials: [Credentials]
    @StateObject private var locationManager = LocationManager()
    @State private var sortOrder: SortOrder = .nearToFar
    @State private var showFavoritesOnly = false
    @State private var showingSortOptions = false
    @State private var showingCredentialsSheet = false
    @State private var isLoading = true  // Add this line

    var sortedStations: ([Station], [Station]) {
        var stationsToSort = self.stations
        
        // Filter by search text
        if !searchText.isEmpty {
            stationsToSort = stationsToSort.filter { $0.id.contains(searchText) || 
                                                   $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Update distances
        if let userLocation = locationManager.location {
            for station in stationsToSort {
                let stationLocation = CLLocation(latitude: station.coordinates.latitude,
                                               longitude: station.coordinates.longitude)
                station.distance = userLocation.distance(from: stationLocation)
            }
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
                }
            }
            .navigationTitle("EMT Stations")
            .navigationBarItems(
                leading: Menu {
                    Picker("Sort Order", selection: $sortOrder) {
                        Label("Nearest First", systemImage: "location").tag(SortOrder.nearToFar)
                        Label("Farthest First", systemImage: "location.slash").tag(SortOrder.farToNear)
                        Label("Alphabetical", systemImage: "textformat").tag(SortOrder.alphabetical)
                    }
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
                await fetchStations()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .sheet(isPresented: $showingNameEditor) {
                NavigationView {
                    Form {
                        TextField("Custom Name", text: $tempCustomName)
                    }
                    .navigationTitle("Edit Name")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingNameEditor = false
                        },
                        trailing: Button("Save") {
                            editingStation?.customName = tempCustomName.isEmpty ? nil : tempCustomName
                            showingNameEditor = false
                        }
                    )
                }
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
    }

    @ViewBuilder
    private func stationRow(for station: Station) -> some View {
        NavigationLink(destination: StopDetailView(stopId: station.id,
                                                  stationCoordinates: station.coordinates)) {
            VStack(alignment: .leading) {
                if let favorite = favorites.first(where: { $0.stationId == station.id }) {
                    Text(favorite.customName ?? station.name)
                        .font(.headline)
                } else {
                    Text(station.name)
                        .font(.headline)
                }
                Text("Lines: \(station.lines.joined(separator: ", "))")
                    .font(.subheadline)
            }
        }
        .swipeActions(edge: .trailing) {
            if let favorite = favorites.first(where: { $0.stationId == station.id }) {
                Button {
                    editingStation = favorite
                    tempCustomName = favorite.customName ?? ""
                    showingNameEditor = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
                
                Button(role: .destructive) {
                    removeFavorite(station)
                } label: {
                    Label("Unfavorite", systemImage: "star.slash")
                }
            } else {
                Button {
                    addFavorite(station)
                } label: {
                    Label("Favorite", systemImage: "star")
                }
                .tint(.yellow)
            }
        }
    }

    private func addFavorite(_ station: Station) {
        let favorite = FavoriteStation(stationId: station.id, name: station.name)
        modelContext.insert(favorite)
    }

    private func removeFavorite(_ station: Station) {
        if let favorite = favorites.first(where: { $0.stationId == station.id }) {
            modelContext.delete(favorite)
        }
    }

    private func fetchStations() async {
        isLoading = true
        guard let credential = credentials.first else {
            errorMessage = "No API credentials found"
            isLoading = false
            return
        }
        
        if useMockData {
            do {
                guard let url = Bundle.main.url(forResource: "stationresponse", withExtension: "json") else {
                    errorMessage = "Mock data file not found"
                    isLoading = false
                    return
                }
                let data = try Data(contentsOf: url)
                let stationsResponse = try JSONDecoder().decode(StationResponse.self, from: data)
                stations = stationsResponse.data
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                print("Mock data error: \(error)")
                isLoading = false
            }
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
            isLoading = false
            
        } catch {
            errorMessage = error.localizedDescription
            print("Error details: \(error)")
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
