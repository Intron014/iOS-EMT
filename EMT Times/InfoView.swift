import SwiftUI
import SwiftData

struct InfoView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingCredentials = false
    @AppStorage("mapPosition") private var mapPosition = "top"
    let apiStats: ApiCounter?
    var refreshCallback: (() -> Void)? = nil
    
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
                    Button("Manage API Credentials") {
                        showingCredentials = true
                    }
                }
                
                Section("Developer") {
                    Text("Developer: Jorge Benjumea")
                    Text("Version: 1.1")
                    Link("GitHub: @intron014", destination: URL(string: "https://github.com/intron014")!)
                }
                
                if let stats = apiStats {
                    Section("API Statistics") {
                        Text("Daily Uses: \(stats.dailyUse)")
                        Text("Current Uses: \(stats.current)")
                        Text("License: \(stats.licenceUse)")
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
