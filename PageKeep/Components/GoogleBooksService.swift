//
//  GoogleBooksService.swift
//  PageKeep
//
//  Created by Allie Sumner on 10/2/25.
//

// Service layer for Google Books API integration
// Handles book search, metadata fetching, and cover image downloads
// Singleton pattern with published state for SwiftUI observation

import Foundation
import SwiftUI
import Combine  // ADD THIS LINE

// MARK: - Data Models for Google Books API Response

struct GoogleBooksResponse: Codable {
    let items: [GoogleBook]?
    let totalItems: Int?
}

struct GoogleBook: Codable, Identifiable {
    let id: String
    let volumeInfo: VolumeInfo
    
    var isbn: String? {
        // Try to find ISBN-13 first, then ISBN-10
        volumeInfo.industryIdentifiers?.first { $0.type == "ISBN_13" }?.identifier ??
        volumeInfo.industryIdentifiers?.first { $0.type == "ISBN_10" }?.identifier
    }
}

struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let publishedDate: String?
    let description: String?
    let pageCount: Int?
    let imageLinks: ImageLinks?
    let industryIdentifiers: [IndustryIdentifier]?
    
    var author: String {
        authors?.joined(separator: ", ") ?? "Unknown Author"
    }
    
    var publicationYear: Int? {
        guard let publishedDate = publishedDate else { return nil }
        let yearString = String(publishedDate.prefix(4))
        return Int(yearString)
    }
}

struct ImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
    let small: String?
    let medium: String?
    let large: String?
    
    // Get the best available image URL (prefer medium quality)
    var bestAvailable: String? {
        medium ?? small ?? large ?? thumbnail ?? smallThumbnail
    }
}

struct IndustryIdentifier: Codable {
    let type: String  // "ISBN_10" or "ISBN_13"
    let identifier: String
}

// MARK: - Google Books Service

class GoogleBooksService: ObservableObject {
    static let shared = GoogleBooksService()
    
    @Published var searchResults: [GoogleBook] = []
    @Published var isSearching = false
    @Published var searchError: String?
    
    private var searchTask: Task<Void, Never>?
    private let baseURL = "https://www.googleapis.com/books/v1/volumes"
    private let apiKey = "AIzaSyC0p2253aIGlhrHdMIEnE7pkbo3OkDEvMs"
    
    // Search for books by title/author
    func searchBooks(query: String) {
        // Cancel any existing search
        searchTask?.cancel()
        
        // Clear previous results if query is empty
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        searchTask = Task {
            await performSearch(query: query)
        }
    }
    
    // Search by ISBN (for future camera feature)
    func searchByISBN(_ isbn: String) {
        searchTask?.cancel()
        
        searchTask = Task {
            await performSearch(query: "isbn:\(isbn)")
        }
    }
    
    @MainActor
    private func performSearch(query: String) async {
        isSearching = true
        searchError = nil
        
        // Build URL with query
        guard var components = URLComponents(string: baseURL) else {
            searchError = "Invalid search query"
            isSearching = false
            return
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: "40"),
            URLQueryItem(name: "key", value: apiKey),
        ]
        guard let url = components.url else {
            searchError = "Invalid search query"
            isSearching = false
            return
        }
        
        do {
            // Fetch data from API
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Decode response
            let decoded = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
            
            // Update results on main thread
            if let items = decoded.items {
                searchResults = items
            } else {
                searchResults = []
            }
            
        } catch {
            if error is CancellationError {
                // Search was cancelled, don't show error
                searchError = nil
            } else {
                searchError = "Failed to search: \(error.localizedDescription)"
                searchResults = []
            }
        }
        
        isSearching = false
    }
    
    // Download book cover image
    func downloadCoverImage(from urlString: String?) async -> Data? {
        guard let urlString = urlString,
              var components = URLComponents(string: urlString) else {
            return nil
        }
        // Upgrade http→https; reject anything that isn't https (no file://, ftp://, etc.).
        if components.scheme == "http" { components.scheme = "https" }
        guard components.scheme == "https", let url = components.url else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Verify it's actually an image by trying to create UIImage
            if UIImage(data: data) != nil {
                return data
            }
        } catch {
        }
        
        return nil
    }
    
    // Clear search results
    func clearResults() {
        searchTask?.cancel()
        searchResults = []
        searchError = nil
    }
}

// MARK: - Helper View for Search Result Row

struct GoogleBookRow: View {
    let book: GoogleBook
    @State private var coverImage: UIImage?
    
    var body: some View {
        HStack(spacing: 12) {
            // Book cover or placeholder
            Group {
                if let coverImage = coverImage {
                    Image(uiImage: coverImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "book.closed")
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 40, height: 60)
            .cornerRadius(4)
            
            // Book info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.volumeInfo.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(book.volumeInfo.author)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let year = book.volumeInfo.publicationYear {
                        Text(String(year))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if let pages = book.volumeInfo.pageCount {
                        Text("\(pages) pages")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Pages unknown")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .task {
            // Load thumbnail asynchronously
            if let urlString = book.volumeInfo.imageLinks?.smallThumbnail {
                if let data = await GoogleBooksService.shared.downloadCoverImage(from: urlString),
                   let image = UIImage(data: data) {
                    coverImage = image
                }
            }
        }
    }
}
