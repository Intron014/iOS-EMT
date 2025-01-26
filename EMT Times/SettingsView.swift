import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Section(header: Text("Startup Preferences")) {
                //     Picker("Default App", selection: .init(
                //         get: { settings.defaultApp ?? "" },
                //         set: { settings.defaultApp = $0.isEmpty ? nil : $0 }
                //     )) {
                //         Text("None").tag("")
                //         ForEach(MiniApp.allCases) { app in
                //             Text(app.rawValue).tag(app.rawValue)
                //         }
                //     }
                //     
                // }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}
