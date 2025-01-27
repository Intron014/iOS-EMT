//
//  EMT_TimesApp.swift
//  EMT Times
//
//  Created by Jorge Benjumea on 13/1/25.
//

import SwiftUI
import SwiftData

// enum MiniApp: String, CaseIterable, Identifiable {
//     case emt = "EMT Bus Times"
//     
//     var id: String { self.rawValue }
//     
//     var iconName: String {
//         switch self {
//         case .emt: return "bus"
//         }
//     }
// }

@main
struct EMT_TimesApp: App {
    @StateObject private var settings = AppSettings.shared
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Credentials.self,
                FavoriteStation.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                EMTView(isSubApp: false)
            }
        }
        .modelContainer(modelContainer)
    }
    
    // @ViewBuilder
    // func destinationView(for app: MiniApp) -> some View {
    //     switch app {
    //     case .emt:
    //         EMTView()
    //     }
    // }
}

// struct AppSelectionView: View {
//     @State private var showingSettings = false
//     let columns = [
//         GridItem(.adaptive(minimum: 150))
//     ]
//     
//     var body: some View {
//         NavigationView {
//             ScrollView {
//                 LazyVGrid(columns: columns, spacing: 20) {
//                     ForEach(MiniApp.allCases) { app in
//                         NavigationLink(destination: destinationView(for: app)) {
//                             VStack {
//                                 Image(systemName: app.iconName)
//                                     .font(.system(size: 30))
//                                     .foregroundColor(.blue)
//                                     .frame(width: 60, height: 60)
//                                     .background(Color.blue.opacity(0.2))
//                                     .clipShape(RoundedRectangle(cornerRadius: 15))
//                                 
//                                 Text(app.rawValue)
//                                     .font(.headline)
//                             }
//                             .padding()
//                             .frame(maxWidth: .infinity)
//                             .background(Color.gray.opacity(0.1))
//                             .cornerRadius(10)
//                         }
//                     }
//                 }
//                 .padding()
//             }
//             .navigationTitle("My Apps")
//             .navigationBarItems(trailing: Button(action: {
//                 showingSettings = true
//             }) {
//                 Image(systemName: "gear")
//             })
//             .sheet(isPresented: $showingSettings) {
//                 SettingsView()
//             }
//         }
//     }
//     
//     @ViewBuilder
//     func destinationView(for app: MiniApp) -> some View {
//         switch app {
//         case .emt:
//             EMTView()
//         }
//     }
// }
