//
//  AnnotationGenreColorPicker.swift
//  PageKeep
//
//  Created by Allie Sumner on 10/13/25.
//

// Genre-aware color picker with 11 palettes (110 total colors)
// Used in AddAnnotationView for selecting meaningful annotation colors
// Includes haptic feedback and multi-line color name support

import SwiftUI

struct AnnotationGenreColorPicker: View {
    @Binding var selectedColor: String?
    let genre: AnnotationGenre
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(genre.colors) { genreColor in
                    Button(action: {
                        selectedColor = genreColor.id
                        
                        // Haptic feedback on selection
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }) {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(genreColor.color)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            selectedColor == genreColor.id ? Color.primary : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                                .overlay(
                                    selectedColor == genreColor.id ?
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 18, weight: .bold))
                                    : nil
                                )
                            
                            Text(genreColor.name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(height: 28, alignment: .top)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
