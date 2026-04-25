//
//  Searchview.swift
//  PageKeep
//
//  Created by Allie Sumner on 9/29/25.
//

// Full-screen search view for filtering library books AND annotations
// Searches by title/author or annotation text with real-time filtering
// Results sorted by status with progress indicators

import SwiftUI
import SwiftData

// Search mode enum
enum SearchMode: String, CaseIterable {
    case books = "Books"
    case annotations = "Annotations"
}

struct SearchView: View {
    @Binding var searchText: String
    @Binding var isPresented: Bool
    @FocusState private var isSearchFocused: Bool
    @Query private var books: [Book]
    @State private var searchMode: SearchMode = .books
    
    private var filteredBooks: [Book] {
        if searchText.isEmpty {
            return []
        } else {
            let filtered = books.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText)
            }
            // Apply sorting to filtered results
            return sortedBooks(filtered)
        }
    }
    
    // Filtered annotations across all books
    private var filteredAnnotations: [(annotation: Annotation, book: Book)] {
        if searchText.isEmpty {
            return []
        } else {
            var results: [(annotation: Annotation, book: Book)] = []
            for book in books {
                for annotation in book.annotations {
                    if annotation.text.localizedCaseInsensitiveContains(searchText) ||
                       (annotation.personalNotes ?? "").localizedCaseInsensitiveContains(searchText) {
                        results.append((annotation: annotation, book: book))
                    }
                }
            }
            // Sort by book title then page number
            return results.sorted { first, second in
                if first.book.title == second.book.title {
                    return first.annotation.pageNumber < second.annotation.pageNumber
                }
                return first.book.title < second.book.title
            }
        }
    }
    
    private func sortedBooks(_ books: [Book]) -> [Book] {
        // First group by status
        let grouped = Dictionary(grouping: books) { $0.status }
        
        // Sort each group according to hybrid approach
        let notStarted = sortByDateAdded(grouped[.notStarted] ?? [])
        let reading = sortByProgress(grouped[.reading] ?? [])
        let completed = sortByDateModified(grouped[.completed] ?? [])
        let abandoned = sortByDateModified(grouped[.abandoned] ?? [])
        
        // Combine in status order
        return notStarted + reading + completed + abandoned
    }
    
    private func sortByDateAdded(_ books: [Book]) -> [Book] {
        return books.sorted { $0.dateAdded > $1.dateAdded }
    }
    
    private func sortByProgress(_ books: [Book]) -> [Book] {
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
    }
    
    private func sortByDateModified(_ books: [Book]) -> [Book] {
        return books.sorted { $0.dateModified > $1.dateModified }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control for search mode
                Picker("Search Mode", selection: $searchMode) {
                    ForEach(SearchMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField(searchMode == .books ? "Search your library" : "Search annotations", text: $searchText)
                        .textFieldStyle(.plain)
                        .focused($isSearchFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Results or help text based on mode
                if searchText.isEmpty {
                    // Help text when no search
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: searchMode == .books ? "magnifyingglass" : "quote.bubble")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        
                        Text(searchMode == .books ? "Search by title or author" : "Search annotation text")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text(searchMode == .books ? "Start typing to search your library" : "Find quotes across all your books")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else if searchMode == .books && filteredBooks.isEmpty {
                    // No book results found
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        
                        Text("No Results")
                            .font(.headline)
                        
                        Text("No books found matching \"\(searchText)\"")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else if searchMode == .annotations && filteredAnnotations.isEmpty {
                    // No annotation results found
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "quote.bubble")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        
                        Text("No Results")
                            .font(.headline)
                        
                        Text("No annotations found matching \"\(searchText)\"")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else if searchMode == .books {
                    // Book results
                    VStack(spacing: 0) {
                        // Results count
                        HStack {
                            Text("\(filteredBooks.count) result\(filteredBooks.count == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        // Book results list - now properly sorted
                        List(filteredBooks) { book in
                            NavigationLink(destination: BookDetailView(book: book)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(book.title)
                                        .font(.headline)
                                        .lineLimit(1)
                                    
                                    Text(book.author)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                    
                                    HStack {
                                        // Status badge
                                        Label {
                                            Text(statusText(for: book.status))
                                                .font(.caption)
                                        } icon: {
                                            Image(systemName: statusIcon(for: book.status))
                                                .font(.caption)
                                        }
                                        .foregroundStyle(statusColor(for: book.status))
                                        
                                        if book.status == .reading && book.totalPages > 0 {
                                            Text("• \(Int(book.progress * 100))% complete")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.top, 2)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(.plain)
                    }
                } else {
                    // Annotation results
                    VStack(spacing: 0) {
                        // Results count
                        HStack {
                            Text("\(filteredAnnotations.count) result\(filteredAnnotations.count == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        // Annotation results list
                        List(filteredAnnotations, id: \.annotation.id) { result in
                            NavigationLink(destination: BookDetailView(book: result.book)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    // Annotation text
                                    Text(result.annotation.text)
                                        .font(.subheadline)
                                        .lineLimit(3)
                                        .foregroundStyle(.primary)
                                    
                                    // Book info and page number
                                    HStack {
                                        Image(systemName: "book")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Text(result.book.title)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                        
                                        Text("• Page \(result.annotation.pageNumber)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Spacer()
                                        
                                        // Color indicator if present
                                        if let color = result.annotation.color {
                                            Circle()
                                                .fill(result.annotation.displayColor)
                                                .frame(width: 8, height: 8)
                                        }
                                    }
                                    
                                    // Personal notes if present
                                    if let notes = result.annotation.personalNotes, !notes.isEmpty {
                                        Text(notes)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                            .italic()
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        searchText = ""
                        isPresented = false
                    }
                }
            }
            .onAppear {
                isSearchFocused = true
            }
        }
    }
    
    private func statusText(for status: BookStatus) -> String {
        switch status {
        case .notStarted: return "Not Started"
        case .reading: return "Reading"
        case .completed: return "Completed"
        case .abandoned: return "Abandoned"
        }
    }
    
    private func statusIcon(for status: BookStatus) -> String {
        switch status {
        case .notStarted: return "bookmark"
        case .reading: return "book"
        case .completed: return "checkmark.circle"
        case .abandoned: return "xmark.circle"
        }
    }
    
    private func statusColor(for status: BookStatus) -> Color {
        switch status {
        case .notStarted: return .orange
        case .reading: return .blue
        case .completed: return .green
        case .abandoned: return .red
        }
    }
}
