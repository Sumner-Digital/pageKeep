//
//  BookRowView.swift
//  PageKeep
//
//  Created by Allie Sumner on 9/26/25.
//

// Individual row view for list display mode
// Shows mini cover, title, author, progress bar, and annotation count
// Includes status-specific gradient fallbacks

import SwiftUI

struct BookRowView: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 12) {
            // Mini book cover (45x68)
            Group {
                if let coverData = book.coverImageData,
                   let uiImage = UIImage(data: coverData) {
                    // Real book cover
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 45, height: 68)
                        .clipped()
                        .cornerRadius(6)
                } else {
                    // Gradient fallback
                    RoundedRectangle(cornerRadius: 6)
                        .fill(gradientForBook)
                        .frame(width: 45, height: 68)
                        .overlay(
                            Image(systemName: statusIcon)
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.8))
                        )
                }
            }
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            
            // Book info
            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                // Progress info - ORIGINAL LAYOUT WITH SHORTER PROGRESS BAR
                HStack(spacing: 8) {
                    // Progress bar - SHORTER FIXED WIDTH
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 4)
                            
                            // Progress fill
                            RoundedRectangle(cornerRadius: 2)
                                .fill(progressColor)
                                .frame(width: min(160, geometry.size.width) * progressPercentage, height: 4)
                        }
                    }
                    .frame(maxWidth: 160, maxHeight: 4) // LIMITED WIDTH - won't grow beyond 140
                    
                    Spacer(minLength: 0)
                    
                    // Page count - RIGHT ALIGNED
                    Text("\(book.currentPage)/\(book.totalPages)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 70, alignment: .trailing) // Increased width for 4-digit numbers
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    // Annotation indicator
                    if !book.annotations.isEmpty {
                        Image(systemName: "quote.bubble.fill")
                            .font(.caption)
                            .foregroundStyle(Color(.annotationTeal))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Computed Properties
    
    private var progressPercentage: Double {
        guard book.totalPages > 0 else { return 0 }
        return Double(book.currentPage) / Double(book.totalPages)
    }
    
    private var progressColor: Color {
        switch book.status {
        case .notStarted:
            return .gray
        case .reading:
            return .blue
        case .completed:
            return .green
        case .abandoned:
            return .orange
        }
    }
    
    private var statusIcon: String {
        switch book.status {
        case .notStarted:
            return "book"
        case .reading:
            return "bookmark.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .abandoned:
            return "book.closed.fill"
        }
    }
    
    private var gradientForBook: LinearGradient {
        let colors = gradientColors(for: book.status)
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func gradientColors(for status: BookStatus) -> [Color] {
        switch status {
        case .notStarted:
            return [Color.gray.opacity(0.6), Color.gray.opacity(0.8)]
        case .reading:
            return [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]
        case .completed:
            return [Color.green.opacity(0.7), Color.teal.opacity(0.7)]
        case .abandoned:
            return [Color.orange.opacity(0.7), Color.red.opacity(0.7)]
        }
    }
}

#Preview {
    let books: [Book] = {
        let b1 = Book(
            title: "The Great Gatsby",
            author: "F. Scott Fitzgerald",
            totalPages: 180,
            currentPage: 89
        )
        b1.status = .reading
        
        let b2 = Book(
            title: "To Kill a Mockingbird",
            author: "Harper Lee",
            totalPages: 281,
            currentPage: 281
        )
        b2.status = .completed
        
        let b3 = Book(
            title: "1984",
            author: "George Orwell",
            totalPages: 328,
            currentPage: 45
        )
        b3.status = .abandoned
        
        return [b1, b2, b3]
    }()
    
    List {
        ForEach(books, id: \.id) { book in
            BookRowView(book: book)
        }
    }
}
