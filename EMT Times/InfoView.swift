import SwiftUI
import SwiftData

struct InfoView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingCredentials = false
    @AppStorage("mapPosition") private var mapPosition = "top"
    @AppStorage("mainView") private var mainView = "list"
    @AppStorage("showBusDistances") var showBusDistances = true
    @AppStorage("showUserLocation") var showUserLocation = false
    @AppStorage("showDataSourceAlert") var showDataSourceAlert = false
    let apiStats: ApiCounter?
    var refreshCallback: (() -> Void)? = nil
    @State private var showingFullSizeIcon: String?
    
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
    
    private func changeAppIcon(to iconName: String?) {
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("Error changing app icon: \(error.localizedDescription)")
            }
        }
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

                    Picker("Default View", selection: $mainView) {
                        Label("List View", systemImage: "list.bullet").tag("list")
                        Label("Map View", systemImage: "map").tag("map")
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
                
                Section("App Icons") {
                    HStack {
                        Spacer()
                        VStack {
                            Image("DupAppIcon")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .cornerRadius(10)
                                .onTapGesture {
                                    showingFullSizeIcon = "DupAppIcon"
                                }
                            Text("By Carmen")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack {
                            Image("FavIcon")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .cornerRadius(10)
                                .onTapGesture {
                                    showingFullSizeIcon = "FavIcon"
                                }
                            Text("By Marta")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("About")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .sheet(isPresented: Binding<Bool>(
                get: { showingFullSizeIcon != nil },
                set: { if !$0 { showingFullSizeIcon = nil } }
            )) {
                if let iconName = showingFullSizeIcon {
                    VStack {
                        Image(iconName)
                            .resizable()
                            .scaledToFit()
                            .padding()
                        Button("Close") {
                            showingFullSizeIcon = nil
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCredentials) {
                CredentialsView(isPresented: $showingCredentials, refreshCallback: refreshCallback)
            }
        }
    }
}
