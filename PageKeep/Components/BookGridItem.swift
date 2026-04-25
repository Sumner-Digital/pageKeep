//
//  BookGridItem.swift
//  PageKeep
//
//  Created by Allie Sumner on 9/26/25.
//

// Individual grid cell for book display
// Shows cover (or gradient placeholder), title, author, and annotation indicator
// Fixed sizing for consistent grid layout

import SwiftUI

struct BookGridItem: View {
    let book: Book
    
    var body: some View {
        VStack(spacing: 8) {
            // Book cover with annotation indicator
            ZStack(alignment: .topTrailing) {
                BookCoverView(book: book)
                
                // Annotation indicator (top-right)
                if !book.annotations.isEmpty {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .offset(x: -4, y: 4)
                }
            }
            
            BookInfoText(book: book)
        }
    }
}

struct BookCoverView: View {
    let book: Book
    
    var body: some View {
        Group {
            if let coverData = book.coverImageData,
               let uiImage = UIImage(data: coverData) {
                // Real book cover
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 150)
                    .clipped()
                    .cornerRadius(8)
            } else {
                // Gradient fallback
                RoundedRectangle(cornerRadius: 8)
                    .fill(gradientForStatus(book.status))
                    .frame(width: 100, height: 150)
                    .overlay(
                        Image(systemName: statusIcon(book.status))
                            .font(.largeTitle)
                            .foregroundStyle(.white.opacity(0.7))
                    )
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 4, x: -3, y: 2)
    }
    
    private func gradientForStatus(_ status: BookStatus) -> LinearGradient {
        let colors = gradientColors(for: status)
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
    
    private func statusIcon(_ status: BookStatus) -> String {
        switch status {
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
}

struct BookInfoText: View {
    let book: Book
    
    var body: some View {
        VStack(spacing: 4) {
            Text(book.title)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 32, alignment: .top)  // Fixed height for 2 lines
            
            Text(book.author)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(height: 16, alignment: .top)  // Fixed height for author
        }
        .frame(width: 100)
    }
}

struct ProgressBarView: View {
    let progress: Double
    let status: BookStatus
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(progressColor)
                    .frame(width: geometry.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
    }
    
    private var progressColor: Color {
        switch status {
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
}
