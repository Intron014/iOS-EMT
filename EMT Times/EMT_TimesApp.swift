//
//  EMT_TimesApp.swift
//  EMT Times
//
//  Created by Jorge Benjumea on 13/1/25.
//

import SwiftUI
import SwiftData


@main
struct EMT_TimesApp: App {
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
}