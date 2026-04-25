//
//  PageKeepApp.swift
//  PageKeep
//
//  Created by Allie Sumner on 9/26/25.
//

// App entry point - Sets up SwiftData schema and launches main library view

import SwiftUI
import SwiftData

@main
struct PageKeepApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Book.self,
            Annotation.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            LibraryView()
                .modelContainer(sharedModelContainer)
        }
    }
}
