//
//  LibraryStatsView.swift
//  PageKeep
//
//  Created by Allie Sumner on 9/26/25.
//

// Statistics dashboard shown at top of Library view
// Displays: Currently Reading count, Completed This Year, Total Pages Read
// Toggleable via stats button in navigation bar

import SwiftUI
import SwiftData

struct LibraryStatsView: View {
    @Query private var books: [Book]
    
    private var currentlyReading: Int {
        books.filter { $0.status == .reading }.count
    }
    
    private var completedThisYear: Int {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        return books.filter { book in
            book.status == .completed &&
            book.dateCompleted != nil &&
            calendar.component(.year, from: book.dateCompleted!) == currentYear
        }.count
    }
    
    private var totalPagesRead: Int {
        books.reduce(0) { total, book in
            if book.status == .completed {
                return total + book.totalPages
            } else {
                return total + book.currentPage
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Reading",
                value: "\(currentlyReading)",
                systemImage: "book",
                color: .blue
            )
            
            StatCard(
                title: "This Year",
                value: "\(completedThisYear)",
                systemImage: "checkmark.circle",
                color: .green
            )
            
            StatCard(
                title: "Pages",
                value: "\(totalPagesRead)",
                systemImage: "doc.text",
                color: .purple
            )
        }
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
