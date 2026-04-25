//
//  EditTotalPagesView.swift
//  PageKeep
//
//  Created by Allie Sumner on 9/26/25.
//

// Inline editing component for updating total page count
// Includes validation to prevent current page exceeding total
// Used in BookDetailView for page count corrections

import SwiftUI

struct EditTotalPagesView: View {
    @Bindable var book: Book
    @Binding var totalPagesText: String
    @Binding var isEditing: Bool
    var focusedField: FocusState<BookDetailView.Field?>.Binding
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Enter Total Pages")
                .font(.subheadline)
                .fontWeight(.medium)
            
            TextField("Number of pages", text: $totalPagesText)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .focused(focusedField, equals: .totalPages)
                .onSubmit {
                    saveTotalPages()
                }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    isEditing = false
                    focusedField.wrappedValue = nil
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Save") {
                    saveTotalPages()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .alert("Page Count Issue", isPresented: $showingAlert) {
            Button("OK") {
                focusedField.wrappedValue = .totalPages
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveTotalPages() {
        guard let newTotal = Int(totalPagesText), newTotal > 0 else {
            alertMessage = "Please enter a valid number greater than 0"
            showingAlert = true
            return
        }
        
        // Check if current page exceeds new total
        if book.currentPage > newTotal {
            alertMessage = "You're on page \(book.currentPage), but the book only has \(newTotal) pages. Please enter a larger number or update your current page first."
            showingAlert = true
            return
        }
        
        book.totalPages = newTotal
        book.dateModified = Date()
        
        // If book is marked completed but current page doesn't match total, update it
        if book.status == .completed {
            book.currentPage = newTotal
        }
        
        isEditing = false
        focusedField.wrappedValue = nil
    }
}
