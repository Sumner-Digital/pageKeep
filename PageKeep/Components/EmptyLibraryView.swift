//
//  EmptyLibraryView.swift
//  PageKeep
//
//  Created by Allie Sumner on 9/26/25.
//

// Empty state view shown when library has no books
// Provides clear call-to-action to add first book
// Displayed in main Library view

import SwiftUI

struct EmptyLibraryView: View {
    @Binding var showingAddBook: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            
            Text("Your Library is Empty")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first book to get started")
                .foregroundStyle(.secondary)
            
            Button {
                showingAddBook = true
            } label: {
                Label("Add Your First Book", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}
