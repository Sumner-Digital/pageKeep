//
//  Library.swift
//  PageKeep
//
//  Created by Allie Sumner on 9/26/25.
//

// Main library view - Entry point for the app
// Displays books in grid or list format with toggleable stats
// Includes search and add book functionality


import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @State private var showingAddBook = false
    @State private var showingSearch = false
    @State private var searchText = ""
    @State private var showingStats = true
    @State private var showingSettings = false
    @State private var selectedViewMode = ViewMode.list
    
    enum ViewMode: String, CaseIterable {
        case list = "List"
        case grid = "Grid"
        
        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .grid: return "square.grid.2x2"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if books.isEmpty {
                    EmptyLibraryView(showingAddBook: $showingAddBook)
                } else {
                    VStack(spacing: 0) {
                        // Stats section - now toggleable
                        if showingStats && !books.isEmpty {
                            LibraryStatsView()
                                .padding(.vertical, 12)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // View mode picker
                        Picker("View Mode", selection: $selectedViewMode) {
                            ForEach(ViewMode.allCases, id: \.self) { mode in
                                Label(mode.rawValue, systemImage: mode.icon)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        
                        // Book display
                        if selectedViewMode == .list {
                            BookListView(books: filteredBooks, searchText: .constant(""), showingStats: $showingStats)
                        } else {
                            BookGridView(books: filteredBooks, showingStats: $showingStats)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.primary)
                }
                ToolbarItem(placement: .principal) {
                    Text("PageKeep")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.primary)

                    Button {
                        showingAddBook = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.primary)
                }
            }
            .sheet(isPresented: $showingAddBook) {
                AddBookView()
            }
            .sheet(isPresented: $showingSearch) {
                SearchView(searchText: $searchText, isPresented: $showingSearch)
                    .onDisappear {
                        searchText = ""
                    }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private var filteredBooks: [Book] {
        if searchText.isEmpty {
            return books
        } else {
            return books.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
