//
//  BookDetail.swift
//  PageKeep
//
//  Created by Allie Sumner on 9/26/25.
//

// Detailed view for individual books
// Shows cover, progress tracking, status management, and annotations
// Includes Google Books API refresh and haptic feedback

import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var book: Book
    @StateObject private var booksService = GoogleBooksService.shared
    
    @State private var isEditingProgress = false
    @State private var isEditingTotalPages = false
    @State private var totalPagesText = ""
    @State private var currentPageText = ""
    @State private var showingFullDescription = false
    @State private var showingSearchResults = false
    @State private var showUpdateAlert = false
    @State private var showingAddAnnotation = false
    @State private var selectedAnnotation: Annotation? = nil
    @State private var annotationToDelete: Annotation? = nil
    @State private var showDeleteConfirmation = false
    @State private var selectedColorFilter: String? = nil  // Filter state
    @State private var showAbandonConfirmation = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case currentPage
        case totalPages
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Book Cover Section
                VStack(spacing: 16) {
                    if let coverData = book.coverImageData,
                       let uiImage = UIImage(data: coverData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 300)
                            .clipped()
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(gradientForStatus)
                            .frame(width: 200, height: 300)
                            .overlay(
                                Image(systemName: statusIcon)
                                    .font(.system(size: 60))
                                    .foregroundStyle(.white.opacity(0.8))
                            )
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    VStack(spacing: 4) {
                        Text(book.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if let year = book.publicationYear {
                            Text("Published \(String(year))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Description Section
                if let description = book.bookDescription {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(showingFullDescription ? nil : 3)
                        
                        if description.count > 150 {
                            Button(action: { showingFullDescription.toggle() }) {
                                Text(showingFullDescription ? "Show Less" : "Show More")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Add Annotation Button
                Button(action: {
                    showingAddAnnotation = true
                }) {
                    HStack {
                        Image(systemName: "quote.bubble")
                        Text("Add Annotation")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                // Status Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Status")
                        .font(.headline)

                    HStack(spacing: 12) {
                        StatusButton(title: "Not Started", status: .notStarted, currentStatus: book.status) {
                            book.status = .notStarted
                            book.currentPage = 0
                            book.dateModified = Date()
                        }

                        StatusButton(title: "Reading", status: .reading, currentStatus: book.status) {
                            book.status = .reading
                            book.dateModified = Date()
                        }

                        StatusButton(title: "Completed", status: .completed, currentStatus: book.status) {
                            book.status = .completed
                            book.currentPage = book.totalPages
                            book.dateModified = Date()
                            book.dateCompleted = Date()

                            // Celebration haptic feedback
                               let success = UINotificationFeedbackGenerator()
                               success.notificationOccurred(.success)
                        }

                        StatusButton(title: "Abandoned", status: .abandoned, currentStatus: book.status) {
                            showAbandonConfirmation = true
                        }
                    }
                    .font(.caption)
                }
                .padding(.horizontal)

                // Reading Progress Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reading Progress")
                        .font(.headline)
                    
                    if book.totalPages > 0 {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Page \(book.currentPage) of \(book.totalPages)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(book.progress * 100))%")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(progressColor)
                                        .frame(width: geometry.size.width * book.progress, height: 8)
                                }
                            }
                            .frame(height: 8)
                            
                            HStack(spacing: 12) {
                                if isEditingProgress {
                                    TextField("Current Page", text: $currentPageText)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .currentPage)
                                        .onAppear {
                                            currentPageText = String(book.currentPage)
                                            focusedField = .currentPage
                                        }
                                        .onSubmit {
                                            saveCurrentPage()
                                        }
                                } else {
                                    Button("Update Progress") {
                                        // Close total pages editing if open
                                        if isEditingTotalPages {
                                            isEditingTotalPages = false
                                            totalPagesText = ""
                                        }
                                        isEditingProgress = true
                                    }
                                    .buttonStyle(.bordered)
                                }
                                
                                if isEditingTotalPages {
                                    TextField("Total Pages", text: $totalPagesText)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .totalPages)
                                        .onAppear {
                                            totalPagesText = String(book.totalPages)
                                            focusedField = .totalPages
                                        }
                                        .onSubmit {
                                            saveTotalPages()
                                        }
                                } else {
                                    Button("Edit Total Pages") {
                                        // Close progress editing if open
                                        if isEditingProgress {
                                            isEditingProgress = false
                                            currentPageText = ""
                                        }
                                        isEditingTotalPages = true
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "book.pages")
                                    .foregroundStyle(.secondary)
                                Text("No page count set")
                                    .foregroundStyle(.secondary)
                            }
                            
                            if isEditingTotalPages {
                                TextField("Total Pages", text: $totalPagesText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .totalPages)
                                    .onAppear {
                                        totalPagesText = ""
                                        focusedField = .totalPages
                                    }
                                    .onSubmit {
                                        saveTotalPages()
                                    }
                            } else {
                                Button("Add Page Count") {
                                    isEditingTotalPages = true
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Annotations Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Annotations")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(filteredAnnotations.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        // Filter menu - only show if there are annotations
                        if !sortedAnnotations.isEmpty {
                            Menu {
                                Button(action: {
                                    selectedColorFilter = nil
                                }) {
                                    Label("Clear Filter", systemImage: "xmark.circle")
                                }
                                
                                Divider()
                                
                                ForEach(uniqueColorsInBook, id: \.id) { colorInfo in
                                    Button(action: {
                                        selectedColorFilter = colorInfo.id
                                    }) {
                                        HStack {
                                            Circle()
                                                .fill(colorInfo.color)
                                                .frame(width: 12, height: 12)
                                            Text(colorInfo.name)
                                            Spacer()
                                            Text("(\(colorInfo.count))")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: selectedColorFilter != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                    .foregroundStyle(selectedColorFilter != nil ? .blue : .primary)
                            }
                        }
                    }
                    
                    if filteredAnnotations.isEmpty && selectedColorFilter != nil {
                        // Filtered empty state
                        VStack(spacing: 12) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            
                            Text("No annotations with this color")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Button("Clear Filter") {
                                selectedColorFilter = nil
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else if sortedAnnotations.isEmpty {
                        // Empty state
                        VStack(spacing: 12) {
                            Image(systemName: "quote.bubble")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            
                            Text("No annotations yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("Tap \"Add Annotation\" to save your favorite quotes and passages")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else {
                        // List of annotations
                        ForEach(filteredAnnotations) { annotation in
                            Button(action: {
                                selectedAnnotation = annotation
                            }) {
                                AnnotationCard(annotation: annotation) {
                                    annotationToDelete = annotation
                                    showDeleteConfirmation = true
                                }
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                }
                .padding(.horizontal)
                
                // Fetch Book Information Section (only for missing data)
                if book.coverImageData == nil || book.bookDescription == nil {
                    VStack(spacing: 8) {
                        Button(action: {
                            let query = "\(book.title) \(book.author)".trimmingCharacters(in: .whitespaces)
                            booksService.searchBooks(query: query)
                            showingSearchResults = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                Text("Fetch Book Information")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .cornerRadius(10)
                        }
                        
                        if booksService.isSearching {
                            ProgressView()
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Metadata Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Metadata")
                        .font(.headline)
                    
                    if let isbn = book.isbn {
                        MetadataRow(label: "ISBN", value: isbn)
                    }
                    
                    MetadataRow(label: "Date Added", value: book.dateAdded.formatted(date: .abbreviated, time: .omitted))
                    
                    if book.status == .completed {
                        MetadataRow(label: "Date Completed", value: book.dateModified.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .onAppear {
            selectedColorFilter = nil
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: book.currentPage) { _, newValue in
            // Only auto-update status if not Abandoned (Abandoned is manual only)
            guard book.status != .abandoned else {
                book.dateModified = Date()
                return
            }
            
            // Auto-update status based on progress
            if newValue == 0 {
                book.status = .notStarted
            } else if newValue >= book.totalPages && book.totalPages > 0 {
                book.status = .completed
            } else if newValue > 0 {
                book.status = .reading
            }
            
            book.dateModified = Date()
        }
        .sheet(isPresented: $showingSearchResults) {
            BookSearchResultsView(
                searchResults: booksService.searchResults,
                onSelect: { selectedBook in
                    applyBookData(selectedBook)
                    showingSearchResults = false
                    showUpdateAlert = true
                    
                    // Auto-dismiss after 1.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showUpdateAlert = false
                    }
                }
            )
        }
        .sheet(isPresented: $showingAddAnnotation) {
            AddAnnotationView(book: book, annotation: nil)
        }
        .sheet(item: $selectedAnnotation) { annotation in
            AddAnnotationView(book: book, annotation: annotation)
        }
        
        .alert("Delete Annotation", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let annotation = annotationToDelete {
                    deleteAnnotation(annotation)
                    annotationToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                annotationToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this annotation?")
        }
        .alert("Abandon Book?", isPresented: $showAbandonConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Abandon", role: .destructive) {
                book.status = .abandoned
                book.dateModified = Date()
                book.dateCompleted = Date()
            }
        } message: {
            Text("Your progress will be saved in case you want to return to this book later.")
        }
        .overlay(alignment: .top) {
            if showUpdateAlert {
                SuccessHUD()
                    .padding(.top, 80)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .toolbar {
            // Add refresh button in top right when book has complete data
            if book.coverImageData != nil && book.bookDescription != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let query = "\(book.title) \(book.author)".trimmingCharacters(in: .whitespaces)
                        booksService.searchBooks(query: query)
                        showingSearchResults = true
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    if isEditingProgress {
                        saveCurrentPage()
                    }
                    if isEditingTotalPages {
                        saveTotalPages()
                    }
                    focusedField = nil
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func deleteAnnotation(_ annotation: Annotation) {
        withAnimation(.easeInOut(duration: 0.3)) {
            book.annotations.removeAll { $0.id == annotation.id }
        }
        modelContext.delete(annotation)
        book.dateModified = Date()
    }
    
    private func saveCurrentPage() {
        if let page = Int(currentPageText), page >= 0 {
            book.currentPage = page
            book.dateModified = Date()
        }
        isEditingProgress = false
    }
    
    private func saveTotalPages() {
        if let pages = Int(totalPagesText), pages > 0 {
            book.totalPages = pages
            book.dateModified = Date()
        }
        isEditingTotalPages = false
    }
    
    private func applyBookData(_ googleBook: GoogleBook) {
        // Update title and author (with proper capitalization)
        book.title = googleBook.volumeInfo.title
        book.author = googleBook.volumeInfo.author
        
        // Update page count if available
        if let pageCount = googleBook.volumeInfo.pageCount {
            book.totalPages = pageCount
        }
        
        // Update description
        book.bookDescription = googleBook.volumeInfo.description
        
        // Update publication year
        book.publicationYear = googleBook.volumeInfo.publicationYear
        
        // Update ISBN
        book.isbn = googleBook.isbn
        
        // Update Google Books ID
        book.googleBooksID = googleBook.id
        
        // Download cover image
        if let imageURL = googleBook.volumeInfo.imageLinks?.bestAvailable {
            Task {
                if let imageData = await booksService.downloadCoverImage(from: imageURL) {
                    await MainActor.run {
                        book.coverImageData = imageData
                        book.dateModified = Date()
                    }
                } else {
                    // Cover download failed - book info is still updated, just no cover
                }
            }
        }
        
        book.dateModified = Date()
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
    
    private var sortedAnnotations: [Annotation] {
        book.annotations.sorted { $0.pageNumber < $1.pageNumber }
    }
    
    // Filtered annotations based on selected color
    private var filteredAnnotations: [Annotation] {
        guard let filter = selectedColorFilter else {
            return sortedAnnotations
        }
        return sortedAnnotations.filter { $0.color == filter }
    }
    
    // Get unique colors used in annotations, sorted by frequency
    private var uniqueColorsInBook: [(id: String, name: String, color: Color, count: Int)] {
        // Group annotations by color
        let colorGroups = Dictionary(grouping: sortedAnnotations.filter { $0.color != nil }) { $0.color! }
        
        // Map to color info with counts
        let colorInfos = colorGroups.compactMap { (colorId, annotations) -> (id: String, name: String, color: Color, count: Int)? in
            guard let firstAnnotation = annotations.first else { return nil }
            return (
                id: colorId,
                name: firstAnnotation.colorMeaningfulName,
                color: firstAnnotation.displayColor,
                count: annotations.count
            )
        }
        
        // Sort by frequency (most used first)
        return colorInfos.sorted { $0.count > $1.count }
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
    
    private var gradientForStatus: LinearGradient {
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

// MARK: - Supporting Views

struct StatusButton: View {
    let title: String
    let status: BookStatus
    let currentStatus: BookStatus
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(currentStatus == status ? Color.blue : Color.gray.opacity(0.2))
                .foregroundStyle(currentStatus == status ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

struct MetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }
}

struct SuccessHUD: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Updated")
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Book Search Results View (reused)

struct BookSearchResultsView: View {
    let searchResults: [GoogleBook]
    let onSelect: (GoogleBook) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var booksService = GoogleBooksService.shared
    
    @State private var searchText = ""
    @State private var searchTimer: Timer?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar at top
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Refine search...", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Results list
                Group {
                    if booksService.searchResults.isEmpty {
                        ContentUnavailableView(
                            "No Results",
                            systemImage: "book.closed",
                            description: Text("Try a different search term")
                        )
                    } else {
                        List(booksService.searchResults) { book in
                            Button(action: {
                                onSelect(book)
                            }) {
                                HStack(spacing: 12) {
                                    // Book cover thumbnail
                                    if let thumbnailURL = book.volumeInfo.imageLinks?.bestAvailable,
                                       let url = URL(string: thumbnailURL.replacingOccurrences(of: "http://", with: "https://")) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                        }
                                        .frame(width: 50, height: 75)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    } else {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 50, height: 75)
                                            .overlay(
                                                Image(systemName: "book")
                                                    .foregroundStyle(.gray)
                                            )
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(book.volumeInfo.title)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                            .lineLimit(2)
                                        
                                        Text(book.volumeInfo.author)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                        
                                        if let pageCount = book.volumeInfo.pageCount {
                                            Text("\(pageCount) pages")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: searchText) { _, newValue in
                handleSearchChange(newValue)
            }
        }
    }
    
    private func handleSearchChange(_ newText: String) {
        // Cancel existing timer
        searchTimer?.invalidate()
        
        // If search is empty, don't search
        guard !newText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        // Start new timer for 1 second delay
        searchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            booksService.searchBooks(query: newText)
        }
    }
}
