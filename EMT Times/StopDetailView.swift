import SwiftUI
import SwiftData
import MapKit

struct CoordinateItem: Identifiable, Equatable {
    enum CoordinateType {
        case station
        case bus
    }
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: CoordinateType
    let lineNumber: String?
    
    var markerTintColor: Color {
        type == .station ? .red : .blue
    }

    static func == (lhs: CoordinateItem, rhs: CoordinateItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.type == rhs.type &&
        lhs.lineNumber == rhs.lineNumber
    }
}

struct StopDetailView: View {
    let stopId: String
    let stationCoordinates: CLLocationCoordinate2D
    @State private var arrivalData: ArrivalData?
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var timer: Timer?
    @Query private var credentials: [Credentials]
    @Query private var favorites: [FavoriteStation]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("mapPosition") private var mapPosition = "top"
    @AppStorage("showBusDistances") private var showBusDistances = true
    @StateObject private var locationManager = LocationManager()
    @AppStorage("showUserLocation") private var showUserLocation = false
    @State private var selectedLines: Set<String> = []
    @State private var mapCamera: MapCameraPosition

    init(stopId: String, stationCoordinates: CLLocationCoordinate2D) {
        self.stopId = stopId
        self.stationCoordinates = stationCoordinates
        self._mapCamera = State(initialValue: .region(MKCoordinateRegion(
            center: stationCoordinates,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )))
    }
    
    private func formatArrivalTime(_ seconds: Int) -> String {
        switch seconds {
        case 999999:
            return ">45'"
        case 888888:
            return ">90'"
        default:
            if seconds < 60 {
                return ">>"
            } else {
                let minutes = seconds / 60
                let remainingSeconds = seconds % 60
                if remainingSeconds == 0 {
                    return "\(minutes)'"
                } else {
                    return "\(minutes)' \(remainingSeconds)''"
                }
            }
        }
    }
    
    private var filteredMapItems: [CoordinateItem] {
        var items = [
            CoordinateItem(coordinate: stationCoordinates, type: .station, lineNumber: nil)
        ]
        if let data = arrivalData {
            for arrival in data.Arrive {
                if selectedLines.isEmpty || selectedLines.contains(arrival.line) {
                    let coords = arrival.geometry.coordinates
                    let busCoords = CLLocationCoordinate2D(latitude: coords[1], longitude: coords[0])
                    items.append(CoordinateItem(coordinate: busCoords, type: .bus, lineNumber: arrival.line))
                }
            }
        }
        return items
    }

    private func calculateRegion(for items: [CoordinateItem]) -> MKCoordinateRegion {
        guard !items.isEmpty else {
            return MKCoordinateRegion(
                center: stationCoordinates,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        }

        var minLat = items[0].coordinate.latitude
        var maxLat = items[0].coordinate.latitude
        var minLon = items[0].coordinate.longitude
        var maxLon = items[0].coordinate.longitude

        for item in items {
            minLat = min(minLat, item.coordinate.latitude)
            maxLat = max(maxLat, item.coordinate.latitude)
            minLon = min(minLon, item.coordinate.longitude)
            maxLon = max(maxLon, item.coordinate.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    private var mapView: some View {
        Map(position: Binding(
            get: { mapCamera },
            set: { mapCamera = $0 }
        ), interactionModes: .all) {
            ForEach(filteredMapItems) { item in
                if item.type == .station {
                    Marker("Stop", coordinate: item.coordinate)
                        .tint(item.markerTintColor)
                } else {
                    Marker(item.lineNumber ?? "Bus", systemImage: "bus.fill", coordinate: item.coordinate)
                        .tint(item.markerTintColor)
                }
            }
            
            if showUserLocation {
                UserAnnotation()
            }
        }
        .onChange(of: filteredMapItems) { oldItems, newItems in
            if oldItems.count != newItems.count {
                withAnimation(.smooth(duration: 0.5)) {
                    mapCamera = .region(calculateRegion(for: newItems))
                }
            }
        }
        .frame(height: 200)
        .cornerRadius(10)
        .padding()
    }

    private var isFavorite: Bool {
        favorites.contains { $0.stationId == stopId }
    }

    private func toggleFavorite() {
        if isFavorite {
            if let favorite = favorites.first(where: { $0.stationId == stopId }) {
                modelContext.delete(favorite)
            }
        } else {
            if let stopName = arrivalData?.StopInfo.first?.stopName {
                let favorite = FavoriteStation(stationId: stopId, name: stopName)
                modelContext.insert(favorite)
            }
        }
    }
    
    var body: some View {
        VStack {
            if mapPosition == "top" {
                mapView
            }
            Group {
                if isLoading {
                    ProgressView()
                } else if let data = arrivalData {
                    List {
                        if let stopInfo = data.StopInfo.first {
                            Section("Stop Information") {
                                Text(stopInfo.stopName)
                                Text(stopInfo.Direction)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 4) {
                                        ForEach(Array(Set(data.Arrive.map { $0.line })).sorted(), id: \.self) { line in
                                            LineNumberView(number: line)
                                                .opacity(selectedLines.isEmpty || selectedLines.contains(line) ? 1.0 : 0.3)
                                                .padding(4)
                                                .onTapGesture {
                                                    if selectedLines.contains(line) {
                                                        selectedLines.remove(line)
                                                    } else {
                                                        selectedLines.insert(line)
                                                    }
                                                }
                                        }
                                    }
                                }
                            }
                        }
                        
                        Section("Arriving Buses") {
                            ForEach(data.Arrive.filter { selectedLines.isEmpty || selectedLines.contains($0.line) }) { arrival in
                                VStack(alignment: .leading) {
                                    HStack {
                                        LineNumberView(number: arrival.line)
                                        Spacer()
                                        Text(formatArrivalTime(arrival.estimateArrive))
                                            .foregroundColor(.secondary)
                                    }
                                    Text("To: \(arrival.destination)")
                                    if showBusDistances {
                                        Text("Distance: \(arrival.DistanceBus)m")
                                            .font(.caption)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle(arrivalData?.StopInfo.first?.stopName ?? "Stop Details")
            .task {
                await fetchArrivals()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .refreshable {
                await fetchArrivals()
            }
            .onAppear {
                // Start timer when view appears
                timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                    Task {
                        await fetchArrivals()
                    }
                }
            }
            .onDisappear {
                // Stop timer when view disappears
                timer?.invalidate()
                timer = nil
            }
            if mapPosition == "below" {
                mapView
            }
        }
        .navigationBarItems(
            leading: Button(action: { selectedLines.removeAll() }) {
                Text("Clear Filters")
                    .opacity(selectedLines.isEmpty ? 0 : 1)
            },
            trailing: Button(action: toggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
            }
        )
    }
    
    private func fetchArrivals() async {
        guard let credential = credentials.first else {
            errorMessage = "No API credentials found"
            return
        }
        
        do {
            let token = try await TokenManager.shared.getToken(using: credential)
            
            let url = URL(string: "https://openapi.emtmadrid.es/v2/transport/busemtmad/stops/\(stopId)/arrives/")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("\(token)", forHTTPHeaderField: "accessToken")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody: [String: Any] = [
                "cultureInfo": "EN",
                "Text_StopRequired_YN": "Y",
                "Text_EstimationsRequired_YN": "Y",
                "Text_IncidencesRequired_YN": "N"
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let arrivalResponse = try JSONDecoder().decode(ArrivalResponse.self, from: data)
            arrivalData = arrivalResponse.data.first
            isLoading = false
            
        } catch {
            errorMessage = error.localizedDescription
            print("Error details: \(error)")
            isLoading = false
        }
    }

}
