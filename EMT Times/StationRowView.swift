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
    
    var body: some View {
        NavigationLink(destination: StopDetailView(stopId: station.id, stationCoordinates: station.coordinates)) {
            VStack(alignment: .leading) {
                Text(favorite?.customName ?? station.name)
                    .font(.headline)
                Text("Lines: \(station.lines.joined(separator: ", "))")
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
                        favorite?.customName = tempCustomName.isEmpty ? nil : tempCustomName
                        showingNameEditor = false
                    }
                )
            }
        }
    }
}
