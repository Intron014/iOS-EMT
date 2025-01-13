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
    @State private var showingCredentials = false
    
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
            ContentView()
                .onAppear {
                    checkCredentials()
                }
                .sheet(isPresented: $showingCredentials) {
                    CredentialsView(isPresented: $showingCredentials)
                }
        }
        .modelContainer(modelContainer)
    }
    
    private func checkCredentials() {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Credentials>()
        
        do {
            let credentials = try context.fetch(descriptor)
            showingCredentials = credentials.isEmpty
        } catch {
            showingCredentials = true
        }
    }
}
