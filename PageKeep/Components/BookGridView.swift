//
//  BookGridView.swift
//  PageKeep
//
//  Created by Allie Sumner on 9/26/25.
//

// Grid layout for displaying books organized by status
// Uses adaptive columns with proper sorting per section
// Part of the Library view's display mode options

import SwiftUI
import SwiftData

struct BookGridView: View {
    let books: [Book]
    @Binding var showingStats: Bool
    @State private var lastScrollY: CGFloat = 0

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 16)
    ]
    
    private var booksByStatus: [(status: BookStatus, books: [Book])] {
        let validBooks = books.filter { !$0.isDeleted }
        let grouped = Dictionary(grouping: validBooks) { $0.status }
        
        let sortedGroups: [(BookStatus, [Book])] = [
            (.reading, sortBooks(grouped[.reading] ?? [], for: .reading)),
            (.notStarted, sortBooks(grouped[.notStarted] ?? [], for: .notStarted)),
            (.completed, sortBooks(grouped[.completed] ?? [], for: .completed)),
            (.abandoned, sortBooks(grouped[.abandoned] ?? [], for: .abandoned))
        ]
        
        return sortedGroups.filter { !$0.1.isEmpty }
    }
    
    private func sortBooks(_ books: [Book], for status: BookStatus) -> [Book] {
        switch status {
        case .notStarted:
            return books.sorted { $0.dateAdded > $1.dateAdded }
        case .reading:
            return books.sorted { book1, book2 in
                if book1.totalPages == 0 && book2.totalPages == 0 {
                    return book1.dateModified > book2.dateModified
                } else if book1.totalPages == 0 {
                    return false
                } else if book2.totalPages == 0 {
                    return true
                } else {
                    return book1.progress > book2.progress
                }
            }
        case .completed, .abandoned:
            // Sort by date completed (most recent first)
            return books.sorted {
                // If both have dateCompleted, compare them
                if let date1 = $0.dateCompleted, let date2 = $1.dateCompleted {
                    return date1 > date2
                }
                // If only one has dateCompleted, it goes first
                if $0.dateCompleted != nil { return true }
                if $1.dateCompleted != nil { return false }
                // If neither has dateCompleted (old books), sort by dateAdded
                return $0.dateAdded > $1.dateAdded
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(booksByStatus, id: \.status) { status, statusBooks in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(sectionTitle(for: status))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(statusBooks) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    BookGridItem(book: book)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, newValue in
            let delta = newValue - lastScrollY
            guard abs(delta) > 8 else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                if delta > 0 && !showingStats {
                    showingStats = true
                } else if delta < 0 && showingStats {
                    showingStats = false
                }
            }
            lastScrollY = newValue
        }
    }
    
    private func sectionTitle(for status: BookStatus) -> String {
        switch status {
        case .notStarted: return "Not Started"
        case .reading: return "Currently Reading"
        case .completed: return "Completed"
        case .abandoned: return "Abandoned"
        }
    }
}
