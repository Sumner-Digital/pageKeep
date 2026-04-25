//
//  BookListView.swift
//  PageKeep
//
//  Created by Allie Sumner on 9/26/25.
//

// List layout for displaying books organized by status
// Shows detailed progress bars and annotation indicators
// Part of the Library view's display mode options

import SwiftUI
import SwiftData

struct BookListView: View {
    let books: [Book]
    @Binding var searchText: String
    @Binding var showingStats: Bool
    @State private var lastScrollY: CGFloat = 0

    var body: some View {
        List {
            ForEach(booksByStatus, id: \.key) { status, statusBooks in
                if !statusBooks.isEmpty {
                    Section(headerText(for: status)) {
                        ForEach(statusBooks) { book in
                            NavigationLink(destination: BookDetailView(book: book)) {
                                BookRowView(book: book)
                            }
                        }
                    }
                }
            }
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
    
    private var booksByStatus: [(key: BookStatus, value: [Book])] {
        let validBooks = books.filter { !$0.isDeleted }
        let grouped = Dictionary(grouping: validBooks) { $0.status }
        
        // Sort each group according to the hybrid approach
        let sortedGroups: [(BookStatus, [Book])] = [
            (.reading, sortBooks(grouped[.reading] ?? [], for: .reading)),
            (.notStarted, sortBooks(grouped[.notStarted] ?? [], for: .notStarted)),
            (.completed, sortBooks(grouped[.completed] ?? [], for: .completed)),
            (.abandoned, sortBooks(grouped[.abandoned] ?? [], for: .abandoned))
        ]
        
        return sortedGroups
    }
    
    private func sortBooks(_ books: [Book], for status: BookStatus) -> [Book] {
        switch status {
        case .notStarted:
            // Sort by date added (newest first)
            return books.sorted { $0.dateAdded > $1.dateAdded }
            
        case .reading:
            // Sort by progress (highest percentage first)
            // Books with no pages (0 total) go to the bottom
            return books.sorted { book1, book2 in
                // If either book has no total pages, put it at the bottom
                if book1.totalPages == 0 && book2.totalPages == 0 {
                    // Both have no pages, sort by date modified
                    return book1.dateModified > book2.dateModified
                } else if book1.totalPages == 0 {
                    return false // book1 goes to bottom
                } else if book2.totalPages == 0 {
                    return true  // book2 goes to bottom
                } else {
                    // Both have pages, sort by progress percentage
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
    
    private func headerText(for status: BookStatus) -> String {
        switch status {
        case .notStarted: return "Not Started"
        case .reading: return "Currently Reading"
        case .completed: return "Completed"
        case .abandoned: return "Abandoned"
        }
    }
}
