//
//  Book.swift
//  PageKeep
//
//  Created by Allie Sumner on 9/26/25.
//

// SwiftData model for physical books
// Tracks reading progress, status, and metadata from Google Books API
// Related to Annotation via one-to-many relationship

import Foundation
import SwiftData

@Model
final class Book {
    var title: String
    var author: String
    var totalPages: Int
    var currentPage: Int
    var dateAdded: Date
    var dateModified: Date
    var status: BookStatus
    var dateCompleted: Date?  // When book was marked completed or abandoned
    
    // New fields for Google Books API
    var coverImageData: Data?        // Cached book cover image (medium quality ~30-50KB)
    var publicationYear: Int?        // Year the book was published
    var bookDescription: String?     // Synopsis/description of the book
    var googleBooksID: String?       // Google's unique ID for re-fetching if needed
    var isbn: String?                // ISBN for exact edition matching (future camera feature)
    // In Book.swift, add this property with the other properties:

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Annotation.book)
    var annotations: [Annotation] = []
    
    // Computed property for progress
    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage) / Double(totalPages)
    }
    
    init(title: String,
         author: String,
         totalPages: Int = 0,
         currentPage: Int = 0,
         coverImageData: Data? = nil,
         publicationYear: Int? = nil,
         bookDescription: String? = nil,
         googleBooksID: String? = nil,
         isbn: String? = nil) {
        self.title = title
        self.author = author
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.dateAdded = Date()
        self.dateModified = Date()
        self.dateCompleted = nil
        self.status = currentPage > 0 ? .reading : .notStarted
        self.coverImageData = coverImageData
        self.publicationYear = publicationYear
        self.bookDescription = bookDescription
        self.googleBooksID = googleBooksID
        self.isbn = isbn
    }
}

enum BookStatus: String, Codable {
    case notStarted = "notStarted"
    case reading = "reading"
    case completed = "completed"
    case abandoned = "abandoned"
}
