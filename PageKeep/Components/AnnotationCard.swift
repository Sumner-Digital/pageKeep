//
//  AnnotationCard.swift
//  PageKeep
//
//  Created by Allie Sumner on 10/7/25.
//

// Display card for individual annotations on book detail view
// Features bookmark icon, color coding, and "Read More" for long quotes
// Shows genre label and delete button with confirmation
// NEW: Displays formatted text (underline/strikethrough)

import SwiftUI

struct AnnotationCard: View {
    let annotation: Annotation
    let onDelete: () -> Void
    
    @State private var isExpanded = false
    
    private let readMoreThreshold = 200
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with page number and delete button
            HStack {
                // Page number (no icon)
                Text("Page \(annotation.pageNumber)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Date added
                Text(annotation.dateCreated.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            
            // Quote text with formatting and Read More
            VStack(alignment: .leading, spacing: 8) {
                if needsReadMore {
                    FormattedTextView(
                        text: isExpanded ? annotation.text : truncatedText,
                        formattingData: annotation.formattingData,
                        isExpanded: isExpanded
                    )
                    .font(.body)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Text(isExpanded ? "Show Less" : "Read More")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                } else {
                    FormattedTextView(
                        text: annotation.text,
                        formattingData: annotation.formattingData,
                        isExpanded: true
                    )
                    .font(.body)
                }
            }
            
            // Personal notes (if present)
            if let notes = annotation.personalNotes, !notes.isEmpty {
                Divider()
                
                Text(notes)
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(.secondary)
            }
            
            // Meaningful color name and genre at bottom
            if !annotation.colorMeaningfulName.isEmpty {
                HStack {
                    Circle()
                        .fill(annotation.displayColor)
                        .frame(width: 12, height: 12)
                    
                    Text(annotation.colorMeaningfulName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.5))
                    
                    Text(annotation.annotationGenre.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.7))
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .padding(.leading, 16) // Extra left padding to clear the bookmark
        .background(Color(.systemBackground))
        .overlay(alignment: .topLeading) {
            // Bookmark icon aligned flush to top-left border
            Image(systemName: "bookmark.fill")
                .font(.system(size: 32))
                .foregroundStyle(bookmarkColor)
                .offset(x: -0.5, y: -1.5)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var needsReadMore: Bool {
        annotation.text.count > readMoreThreshold
    }
    
    private var truncatedText: String {
        if annotation.text.count > readMoreThreshold {
            let index = annotation.text.index(annotation.text.startIndex, offsetBy: readMoreThreshold)
            return String(annotation.text[..<index]) + "..."
        }
        return annotation.text
    }
    
    private var bookmarkColor: Color {
        return annotation.displayColor
    }
    
    private var borderColor: Color {
        return annotation.displayColor.opacity(0.3)
    }
}

// MARK: - Formatted Text View

struct FormattedTextView: View {
    let text: String
    let formattingData: Data?
    let isExpanded: Bool
    
    private var attributedString: AttributedString {
        var attributed = AttributedString(text)
        
        // Decode and apply formatting if it exists
        if let data = formattingData,
           let formatting = try? JSONDecoder().decode(TextFormattingData.self, from: data) {
            
            // Apply underline
            for range in formatting.underlineRanges {
                if let swiftRange = Range(NSRange(location: range.start, length: range.end - range.start), in: text),
                   let attrRange = Range(swiftRange, in: attributed) {
                    attributed[attrRange].underlineStyle = .single
                }
            }
            
            // Apply strikethrough
            for range in formatting.strikethroughRanges {
                if let swiftRange = Range(NSRange(location: range.start, length: range.end - range.start), in: text),
                   let attrRange = Range(swiftRange, in: attributed) {
                    attributed[attrRange].strikethroughStyle = .single
                }
            }
        }
        
        return attributed
    }
    
    var body: some View {
        Text(attributedString)
            .foregroundStyle(.primary)
    }
}
