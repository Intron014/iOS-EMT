import SwiftUI
import SwiftData

struct InfoView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingCredentials = false
    @AppStorage("mapPosition") private var mapPosition = "top"
    @AppStorage("showBusDistances") var showBusDistances = true
    @AppStorage("showUserLocation") var showUserLocation = false
    @AppStorage("showDataSourceAlert") var showDataSourceAlert = false
    let apiStats: ApiCounter?
    var refreshCallback: (() -> Void)? = nil
    
    private func formattedLastUpdate() -> String {
        guard let lastUpdate = StationsCache.shared.lastUpdate else {
            return "Never"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastUpdate, relativeTo: Date())
    }
    
    private func refreshCache() {
        StationsCache.shared.clearMemoryCache()
        refreshCallback?()
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Settings") {
                    Picker("Map Position", selection: $mapPosition) {
                        Text("Top").tag("top")
                        Text("Below").tag("below")
                        Text("Hidden").tag("hidden")
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Toggle("Show Your Location", isOn: $showUserLocation)
                    
                    Toggle("Show Bus Distances", isOn: $showBusDistances)
                    
                    Toggle("Show Data Source Alerts", isOn: $showDataSourceAlert)
                    
                    Button("Manage API Credentials") {
                        showingCredentials = true
                    }
                }
                
                Section("Developer") {
                    Text("Developer: Jorge Benjumea")
                    Text("Version: 1.1")
                    Link("GitHub: @intron014", destination: URL(string: "https://github.com/intron014")!)
                }
                
                Section("API Statistics") {
                    if let stats = apiStats {
                        Text("Daily Uses: \(stats.dailyUse)")
                        Text("Current Uses: \(stats.current)")
                        Text("Last Cache Update: \(formattedLastUpdate())")
                            .swipeActions {
                                Button(action: refreshCache) {
                                    Label("Refresh", systemImage: "arrow.clockwise")
                                }
                                .tint(.green)
                            }
                    } else {
                        Text("No API statistics available")
                            .foregroundColor(.secondary)
                    }
                }
                if let stats = apiStats {
                    Section("License"){
                            Text(stats.licenceUse)
                    }
                }
                
            }
            .navigationTitle("About")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .sheet(isPresented: $showingCredentials) {
                CredentialsView(isPresented: $showingCredentials, refreshCallback: refreshCallback)
            }
        }
    }
}
