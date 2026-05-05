//
//  PageKeepApp.swift
//  PageKeep
//
//  Created by Allie Sumner on 9/26/25.
//

// App entry point - Sets up SwiftData schema and launches main library view

import SwiftUI
import SwiftData
import UIKit

@main
struct PageKeepApp: App {

    init() {
        // Force spell-check on globally for every UITextField, overriding
        // iOS's default heuristic that turns spell-check off when autocorrect
        // is off (Phase 4.5 disabled autocorrect on the Add Annotation fields,
        // which silently took spell-check with it).
        //
        // UITextView.appearance() is intentionally NOT set here — SwiftUI's
        // internal VerticalTextView (used by TextField(axis: .vertical))
        // crashes on appearance-proxy traits with a misleading
        // "off the main thread" exception.
        UITextField.appearance().spellCheckingType = .yes
    }

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
