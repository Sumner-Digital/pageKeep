//
//  TextSelectionView.swift
//  PageKeep
//
//  Created on November 4, 2025
//  Phase 6: Camera & OCR Implementation - LIST VERSION
//

import SwiftUI

struct TextSelectionView: View {
    
    // MARK: - Properties
    
    let capturedImage: UIImage
    let textBlocks: [TextBlock]
    let onConfirm: (String) -> Void
    let onCancel: () -> Void
    
    // MARK: - State
    
    @State private var selectedBlockIDs: Set<UUID> = []
    
    // MARK: - Computed Properties
    
    private var selectedCount: Int {
        selectedBlockIDs.count
    }
    
    private var hasSelection: Bool {
        !selectedBlockIDs.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Image preview at top
                    Image(uiImage: capturedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 180)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Header
                    HStack {
                        Text("Tap text blocks to select")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(textBlocks.count) found")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    .padding()
                    
                    // Scrollable list of text blocks
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(textBlocks.enumerated()), id: \.element.id) { index, block in
                                Button(action: {
                                    toggleBlockSelection(block.id)
                                }) {
                                    HStack(alignment: .top, spacing: 12) {
                                        // Selection indicator
                                        ZStack {
                                            Circle()
                                                .strokeBorder(selectedBlockIDs.contains(block.id) ? Color.green : Color.gray, lineWidth: 2)
                                                .frame(width: 24, height: 24)
                                            
                                            if selectedBlockIDs.contains(block.id) {
                                                Circle()
                                                    .fill(Color.green)
                                                    .frame(width: 16, height: 16)
                                            }
                                        }
                                        .padding(.top, 2)
                                        
                                        // Text content
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Text("Block \(index + 1)")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.blue)
                                                
                                                Spacer()
                                                
                                                Text("\(Int(block.confidence * 100))%")
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Text(block.text)
                                                .font(.body)
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .multilineTextAlignment(.leading)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedBlockIDs.contains(block.id) ? Color.green.opacity(0.2) : Color.gray.opacity(0.15))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(selectedBlockIDs.contains(block.id) ? Color.green : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                    
                    // Bottom bar
                    HStack {
                        if hasSelection {
                            Text("\(selectedCount) block\(selectedCount == 1 ? "" : "s") selected")
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        } else {
                            Text("Select text blocks to capture")
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.black.opacity(0.9))
                }
            }
            .navigationTitle("Select Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: handleConfirm) {
                        Text("Confirm")
                            .fontWeight(.semibold)
                    }
                    .disabled(!hasSelection)
                    .foregroundColor(hasSelection ? .green : .gray)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    // MARK: - Methods
    
    private func toggleBlockSelection(_ blockID: UUID) {
        if selectedBlockIDs.contains(blockID) {
            selectedBlockIDs.remove(blockID)
        } else {
            selectedBlockIDs.insert(blockID)
        }
    }

    private func handleConfirm() {
        let selectedBlocks = textBlocks.filter { selectedBlockIDs.contains($0.id) }
        
        guard !selectedBlocks.isEmpty else { return }
        
        let concatenatedText = OCRTextRecognizer.concatenateText(from: selectedBlocks)
        onConfirm(concatenatedText)
    }
}
