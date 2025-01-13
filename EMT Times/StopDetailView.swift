import SwiftUI
import SwiftData

struct StopDetailView: View {
    let stopId: String
    @State private var arrivalData: ArrivalData?
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var timer: Timer?
    @Query private var credentials: [Credentials]
    
    private func formatArrivalTime(_ seconds: Int) -> String {
        switch seconds {
        case 999999:
            return ">45'"
        case 888888:
            return ">90'"
        default:
            if seconds < 60 {
                return "\(seconds)''"
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
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let data = arrivalData {
                List {
                    if let stopInfo = data.StopInfo.first {
                        Section("Stop Information") {
                            Text("Name: \(stopInfo.stopName)")
                            Text("Address: \(stopInfo.Direction)")
                        }
                    }
                    
                    Section("Arriving Buses") {
                        ForEach(data.Arrive) { arrival in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Line \(arrival.line)")
                                        .font(.headline)
                                    Spacer()
                                    Text(formatArrivalTime(arrival.estimateArrive))
                                        .foregroundColor(.secondary)
                                }
                                Text("To: \(arrival.destination)")
                                Text("Distance: \(arrival.DistanceBus)m")
                                    .font(.caption)
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
