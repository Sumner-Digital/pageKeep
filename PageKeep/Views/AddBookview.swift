//
//  AddBook.swift
//  PageKeep
//
//  Created by Allie Sumner on 9/26/25.
//

//
//  AddBook.swift
//  PageKeep
//
//  Created by Allie Sumner on 9/26/25.
//

// Sheet view for adding new books to library
// Features real-time Google Books API search with results dropdown
// Includes duplicate detection and validation

import SwiftUI
import SwiftData

struct AddBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var author = ""
    @State private var totalPagesText = ""
    @State private var currentPageText = ""
    @State private var startReading = true
    @State private var showDuplicateAlert = false
    @State private var duplicateBookTitle = ""
    
    // Google Books API related
    @StateObject private var booksService = GoogleBooksService.shared
    @State private var showAllResults = false
    @State private var searchTimer: Timer?
    @State private var selectedBook: GoogleBook?
    @State private var coverImageData: Data?
    @State private var publicationYear: Int?
    @State private var bookDescription: String?
    @State private var isbn: String?
    @State private var googleBooksID: String?
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, author, totalPages, currentPage
    }
    
    // Computed properties
    private var hasPageError: Bool {
        guard startReading,
              !totalPagesText.isEmpty,
              !currentPageText.isEmpty,
              let total = Int(totalPagesText),
              let current = Int(currentPageText),
              total > 0 else {
            return false
        }
        return current > total
    }
    
    private var pageErrorMessage: String? {
        guard hasPageError,
              let total = Int(totalPagesText) else { return nil }
        return "Current page cannot exceed total pages (\(total))"
    }
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !hasPageError
    }
    
    private var displayedResults: [GoogleBook] {
        if showAllResults {
            return booksService.searchResults
        } else {
            return Array(booksService.searchResults.prefix(5))
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Book Information") {
                    VStack(alignment: .leading, spacing: 0) {
                        // Title field with search
                        TextField("Title", text: $title)
                            .focused($focusedField, equals: .title)
                            .onSubmit { focusedField = .author }
                            .onChange(of: title) { _, newValue in
                                handleSearchChange()  // Use the new unified function
                            }
                        // ADD THIS HELPER TEXT
                        Text("Search by title, author, or both (e.g., 'IT Stephen King')")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                        
                        // Search results dropdown
                        if !booksService.searchResults.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                Divider()
                                    .padding(.top, 8)
                                
                                // Show loading indicator while searching
                                if booksService.isSearching {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .padding()
                                        Spacer()
                                    }
                                } else {
                                    // Results list
                                    ForEach(displayedResults) { book in
                                        Button(action: {
                                            selectBook(book)
                                        }) {
                                            GoogleBookRow(book: book)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        if book.id != displayedResults.last?.id {
                                            Divider()
                                                .padding(.leading, 52)
                                        }
                                    }
                                    
                                    // Show All button
                                    if booksService.searchResults.count > 5 && !showAllResults {
                                        Divider()
                                            .padding(.leading, 52)
                                        
                                        Button(action: {
                                            showAllResults = true
                                        }) {
                                            HStack {
                                                Spacer()
                                                Text("Show All (\(booksService.searchResults.count) results)")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .shadow(radius: 2)
                        }
                    }
                    
                    TextField("Author", text: $author)
                        .focused($focusedField, equals: .author)
                        .onSubmit {
                            if startReading {
                                focusedField = .totalPages
                            }
                        }
                        .onChange(of: author) { _, newValue in
                            handleSearchChange()  // ADD THIS - trigger search when author changes
                        }
                }
                
                // Selected book cover preview
                if let coverImageData = coverImageData,
                   let uiImage = UIImage(data: coverImageData) {
                    Section("Book Cover") {
                        HStack {
                            Spacer()
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 150)
                                .cornerRadius(8)
                                .shadow(radius: 2)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Book details (if available)
                if publicationYear != nil || bookDescription != nil {
                    Section("Book Details") {
                        if let year = publicationYear {
                            HStack {
                                Text("Publication Year")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(year))
                            }
                        }
                        
                        if let description = bookDescription {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Description")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(description)
                                    .font(.caption)
                                    .lineLimit(4)
                            }
                        }
                    }
                }
                
                Section {
                    Toggle("Add to Currently Reading", isOn: $startReading)
                        .onChange(of: startReading) { _, newValue in
                            if !newValue {
                                currentPageText = ""
                                focusedField = nil
                            }
                        }
                    
                    HStack {
                        Text("Total Pages")
                        Spacer()
                        TextField("Optional", text: $totalPagesText)
                            .focused($focusedField, equals: .totalPages)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .onChange(of: totalPagesText) { _, newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered != newValue {
                                    totalPagesText = filtered
                                }
                            }
                            .onSubmit {
                                if startReading {
                                    focusedField = .currentPage
                                }
                            }
                    }
                    
                    if startReading {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Current Page")
                                Spacer()
                                TextField("1", text: $currentPageText)
                                    .focused($focusedField, equals: .currentPage)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                                    .onChange(of: currentPageText) { _, newValue in
                                        let filtered = newValue.filter { $0.isNumber }
                                        if filtered != newValue {
                                            currentPageText = filtered
                                        }
                                    }
                                    .foregroundStyle(hasPageError ? .red : .primary)
                            }
                            
                            if let errorMessage = pageErrorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: hasPageError)
                    }
                } header: {
                                    Text("Reading Progress")
                                } footer: {
                                    if startReading {
                                        Text("Your book will be added to 'Currently Reading'")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Your book will be added to 'Not Started'")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .scrollDismissesKeyboard(.immediately)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                focusedField = nil
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addBook()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                    .foregroundStyle(canSave ? .blue : .gray)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    if focusedField == .totalPages || focusedField == .currentPage {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                    }
                }
            }
            .alert("Book Already Exists", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You already have \"\(duplicateBookTitle)\" in your library.")
            }
            .onAppear {
                booksService.clearResults()
            }
            .onDisappear {
                searchTimer?.invalidate()
                booksService.clearResults()
            }
        }
    }
    
    private func handleSearchChange() {
        
        // Cancel existing timer
        searchTimer?.invalidate()
        
        // Clear selection when manually typing
        if selectedBook != nil {
            selectedBook = nil
        }
        
        // Start new timer for 1 second delay
        searchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Build search query from available fields
            var searchQuery = ""
            if !trimmedTitle.isEmpty && !trimmedAuthor.isEmpty {
                // Both filled - combine them
                searchQuery = "\(trimmedTitle) \(trimmedAuthor)"
            } else if !trimmedTitle.isEmpty {
                // Only title
                searchQuery = trimmedTitle
            } else if !trimmedAuthor.isEmpty {
                // Only author
                searchQuery = trimmedAuthor
            }
            
            if !searchQuery.isEmpty {
                booksService.searchBooks(query: searchQuery)
            } else {
                booksService.clearResults()
            }
            showAllResults = false
        }
    }
    
    
    private func selectBook(_ book: GoogleBook) {
        selectedBook = book
        
        // Fill in the form fields
        title = book.volumeInfo.title
        author = book.volumeInfo.author
        
        if let pageCount = book.volumeInfo.pageCount {
            totalPagesText = String(pageCount)
        }
        
        publicationYear = book.volumeInfo.publicationYear
        bookDescription = book.volumeInfo.description
        isbn = book.isbn
        googleBooksID = book.id
        
        // Download cover image
        Task {
            if let imageUrl = book.volumeInfo.imageLinks?.bestAvailable {
                if let imageData = await booksService.downloadCoverImage(from: imageUrl) {
                    coverImageData = imageData
                } else {
                    // Cover download failed - user can still add the book without cover
                }
            }
        }
        
        // Clear search results and move focus
        booksService.clearResults()
        focusedField = .author
        showAllResults = false
    }
    
    private func checkForDuplicate() -> Bool {
        // Query all books
        let descriptor = FetchDescriptor<Book>()
        guard let allBooks = try? modelContext.fetch(descriptor) else {
            return false
        }
        
        // Check if book with same title and author exists
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        let duplicate = allBooks.first { book in
            book.title.lowercased() == trimmedTitle &&
            book.author.lowercased() == trimmedAuthor
        }
        
        if let duplicate = duplicate {
            duplicateBookTitle = duplicate.title
            return true
        }
        
        return false
    }
    
    private func addBook() {
        guard !hasPageError else { return }
        
        // Check for duplicates
        if checkForDuplicate() {
            showDuplicateAlert = true
            return
        }
        
        let totalPages = Int(totalPagesText) ?? 0
        
        let currentPage: Int
        if startReading {
            if currentPageText.isEmpty {
                currentPage = totalPages > 0 ? 1 : 0
            } else {
                currentPage = Int(currentPageText) ?? 1
            }
        } else {
            currentPage = 0
        }
        
        let newBook = Book(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            author: author.trimmingCharacters(in: .whitespacesAndNewlines),
            totalPages: totalPages,
            currentPage: currentPage,
            coverImageData: coverImageData,
            publicationYear: publicationYear,
            bookDescription: bookDescription,
            googleBooksID: googleBooksID,
            isbn: isbn
        )
        
        if startReading {
            newBook.status = .reading
        } else {
            newBook.status = .notStarted
        }
        
        modelContext.insert(newBook)
        dismiss()
    }
    
}
