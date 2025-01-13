//
//  ContentView.swift
//  EMT Times
//
//  Created by Jorge Benjumea on 13/1/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var errorMessage: String?
    @State private var stations: [Station] = []
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var useMockData = false
    @State private var searchText = ""
    @State private var directStopId: String?
    @Query private var favorites: [FavoriteStation]
    @State private var editingStation: FavoriteStation?
    @State private var showingNameEditor = false
    @State private var tempCustomName = ""
    @State private var showingInfo = false
    @Query private var credentials: [Credentials]

    var sortedStations: ([Station], [Station]) {
        let favoriteIds = Set(favorites.map { $0.stationId })
        let favs = stations.filter { favoriteIds.contains($0.id) }
        let others = stations.filter { !favoriteIds.contains($0.id) }
        
        if searchText.isEmpty {
            return (favs, others)
        }
        
        return (
            favs.filter { $0.id.contains(searchText) || $0.name.localizedCaseInsensitiveContains(searchText) },
            others.filter { $0.id.contains(searchText) || $0.name.localizedCaseInsensitiveContains(searchText) }
        )
    }

    var body: some View {
        NavigationView {
            List {
                if !sortedStations.0.isEmpty {
                    Section("Favorites") {
                        ForEach(sortedStations.0) { station in
                            stationRow(for: station)
                        }
                    }
                }
                
                Section("All Stations") {
                    ForEach(sortedStations.1) { station in
                        stationRow(for: station)
                    }
                }
            }
            .navigationTitle("EMT Stations")
            .navigationBarItems(trailing: Button(action: {
                showingInfo = true
            }) {
                Image(systemName: "info.circle")
            })
            .searchable(text: $searchText, prompt: "Search by stop number or name")
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
        guard let credential = credentials.first else {
            errorMessage = "No API credentials found"
            return
        }
        
        if useMockData {
            do {
                guard let url = Bundle.main.url(forResource: "stationresponse", withExtension: "json") else {
                    errorMessage = "Mock data file not found"
                    return
                }
                let data = try Data(contentsOf: url)
                let stationsResponse = try JSONDecoder().decode(StationResponse.self, from: data)
                stations = stationsResponse.data
            } catch {
                errorMessage = error.localizedDescription
                print("Mock data error: \(error)")
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
            
        } catch {
            errorMessage = error.localizedDescription
            print("Error details: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
