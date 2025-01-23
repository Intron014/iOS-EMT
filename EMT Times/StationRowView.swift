import SwiftUI
import SwiftData

struct StationRowView: View {
    let station: Station
    @Query private var favorites: [FavoriteStation]
    @Environment(\.modelContext) private var modelContext
    @State private var showingNameEditor = false
    @State private var tempCustomName = ""
    
    private var favorite: FavoriteStation? {
        favorites.first(where: { $0.stationId == station.id })
    }
    
    private var formattedLines: String {
        station.lines
            .map { $0.split(separator: "/").first?.description ?? $0 }
            .joined(separator: ", ")
    }
    
    var body: some View {
        NavigationLink(destination: StopDetailView(stopId: station.id, stationCoordinates: station.coordinates)) {
            VStack(alignment: .leading) {
                Text(favorite?.customName ?? station.name)
                    .font(.headline)
                Text("Lines: \(formattedLines)")
                    .font(.subheadline)
            }
        }
        .swipeActions(edge: .trailing) {
            if let favorite = favorite {
                Button {
                    tempCustomName = favorite.customName ?? ""
                    showingNameEditor = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
                
                Button(role: .destructive) {
                    modelContext.delete(favorite)
                } label: {
                    Label("Unfavorite", systemImage: "star.slash")
                }
            } else {
                Button {
                    let favorite = FavoriteStation(stationId: station.id, name: station.name)
                    modelContext.insert(favorite)
                } label: {
                    Label("Favorite", systemImage: "star")
                }
                .tint(.yellow)
            }
        }
        .sheet(isPresented: $showingNameEditor) {
            NavigationStack {
                Form {
                    TextField("Custom Name", text: $tempCustomName)
                        .submitLabel(.done)
                        .onSubmit {
                            favorite?.customName = tempCustomName.isEmpty ? nil : tempCustomName
                            showingNameEditor = false
                        }
                }
                .navigationTitle("Edit Namo")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingNameEditor = false
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Save") {
                            favorite?.customName = tempCustomName.isEmpty ? nil : tempCustomName
                            showingNameEditor = false
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        Button("Reset") {
                            tempCustomName = station.name
                        }
                        .foregroundStyle(.orange)
                    }
                }
            }
            .interactiveDismissDisabled()
            .ignoresSafeArea(.keyboard)
        }
    }
}
