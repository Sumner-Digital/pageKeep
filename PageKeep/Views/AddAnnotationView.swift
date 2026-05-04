//
//  AddAnnotationView.swift
//  PageKeep
//
//  Updated: November 4, 2025
//  Phase 6: Added OCR Camera Integration
//  FIXED: Added formattingData binding for FormattedTextEditor
//
//  LOCATION: Views/AddAnnotationView.swift
//

import SwiftUI
import SwiftData

struct AddAnnotationView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    let book: Book
    let annotation: Annotation?
    
    // MARK: - State - Annotation Data
    
    @State private var text: String
    @State private var pageNumber: String
    @State private var personalNotes: String
    @State private var selectedGenre: AnnotationGenre
    @State private var selectedColor: String?
    @State private var formattingData: TextFormattingData = TextFormattingData()  // NEW - Required for FormattedTextEditor
    
    // MARK: - State - OCR Camera
    
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var detectedTextBlocks: [TextBlock] = []
    @State private var showingTextSelection = false
    @State private var isProcessingOCR = false
    @State private var ocrError: String?
    @State private var showingOCRError = false
    
    // MARK: - State - Permissions
    
    @State private var cameraPermissionGranted = false
    @State private var showingPermissionAlert = false
    
    // MARK: - State - OCR Warning
    @AppStorage("hideOCRWarning") private var hideOCRWarning = false
    @State private var showingOCRWarning = false

    // MARK: - Focus

    @FocusState private var focusedField: Field?

    // FormattedTextEditor (quote) is a UIViewRepresentable wrapping UITextView,
    // so SwiftUI's .focused() doesn't apply. The tap-to-dismiss handler sends
    // resignFirstResponder via UIApplication to dismiss its keyboard too.
    enum Field {
        case pageNumber, personalNotes
    }

    // MARK: - Initialization
    
    init(book: Book, annotation: Annotation? = nil) {
        self.book = book
        self.annotation = annotation
        
        if let annotation = annotation {
            _text = State(initialValue: annotation.text)
            _pageNumber = State(initialValue: String(annotation.pageNumber))
            _personalNotes = State(initialValue: annotation.personalNotes ?? "")
            _selectedGenre = State(initialValue: annotation.annotationGenre)
            _selectedColor = State(initialValue: annotation.color)
            
            // Load existing formatting data if available
            if let data = annotation.formattingData,
               let decoded = try? JSONDecoder().decode(TextFormattingData.self, from: data) {
                _formattingData = State(initialValue: decoded)
            }
        } else {
            _text = State(initialValue: "")
            _pageNumber = State(initialValue: "")
            _personalNotes = State(initialValue: "")
            _selectedGenre = State(initialValue: .general)
            _selectedColor = State(initialValue: nil)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isEditMode: Bool {
        annotation != nil
    }
    
    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !pageNumber.isEmpty &&
        Int(pageNumber) != nil
    }
    
    private var navigationTitle: String {
        isEditMode ? "Edit Annotation" : "Add Annotation"
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            formContent
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
                .onAppear {
                    checkCameraPermission()
                }
                .sheet(isPresented: $showingCamera) {
                    CameraCapture(image: $capturedImage, isPresented: $showingCamera)
                }
                .fullScreenCover(isPresented: $showingTextSelection) {
                    textSelectionContent
                }
                .overlay {
                    ocrProcessingOverlay
                }
                .alert("Camera Access Needed", isPresented: $showingPermissionAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Open Settings") {
                        CameraPermissionManager.openSettings()
                    }
                } message: {
                    Text("Camera access is needed to capture text from your books. Please enable it in Settings.")
                }
                .alert("Text Recognition Failed", isPresented: $showingOCRError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(ocrError ?? "Could not recognize text from the image. Please try again with better lighting or type manually.")
                }
                .onChange(of: capturedImage) { _, newImage in
                    if let image = newImage {
                        processImageWithOCR(image)
                    }
                }
                .alert("Quick Heads Up", isPresented: $showingOCRWarning) {
                    Button("Got It") {
                        showingCamera = true
                    }
                    Button("Don't Show Again") {
                        hideOCRWarning = true
                        showingCamera = true
                    }
                } message: {
                    Text("OCR may take a moment and isn't always perfect. Decorative elements like drop caps may not be detected. You can always edit the text after capture.")
                }
        }
    }
    
    // MARK: - Subviews
    
    private var formContent: some View {
        Form {
            quoteSection
            pageNumberSection
            personalNotesSection
            genreColorSection
        }
        .scrollDismissesKeyboard(.immediately)
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private var quoteSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Quote or Passage \(Text("*").foregroundColor(.red))")
                        .font(.headline)
                    Spacer()
                    
                    Button(action: handleCameraButtonTap) {
                        Image(systemName: "camera")
                            .font(.title3)
                            .foregroundColor(cameraPermissionGranted ? .blue : .gray)
                    }
                    .disabled(!cameraPermissionGranted)
                    .opacity(cameraPermissionGranted ? 1.0 : 0.5)
                }
                
                // FIXED: Now includes formattingData binding
                FormattedTextEditor(
                    text: $text,
                    formattingData: $formattingData,
                    placeholder: "Enter the text you want to save...",
                    autoFocus: annotation == nil
                )
                .frame(minHeight: 150)
            }
        } header: {
            EmptyView()
        }
    }
    
    private var pageNumberSection: some View {
        Section {
            TextField("Page Number", text: $pageNumber)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .pageNumber)
        } header: {
            HStack(spacing: 2) {
                Text("Page Number")
                Text("*")
                    .foregroundColor(.red)
            }
        } 
    }
    
    private var personalNotesSection: some View {
        Section {
            TextField("Optional notes about this passage", text: $personalNotes, axis: .vertical)
                .lineLimit(3...6)
                .focused($focusedField, equals: .personalNotes)
        } header: {
            Text("Personal Notes (Optional)")
        }
    }
    
    private var genreColorSection: some View {
        Section {
            Picker("Genre", selection: $selectedGenre) {
                ForEach(AnnotationGenre.allCases, id: \.self) { genre in
                    Text(genre.displayName).tag(genre)
                }
            }
            .onChange(of: selectedGenre) { _, newGenre in
                if let colorId = selectedColor {
                    let colorExists = newGenre.colors.contains { $0.id == colorId }
                    if !colorExists {
                        selectedColor = nil
                    }
                }
            }
            
            AnnotationGenreColorPicker(
                selectedColor: $selectedColor,
                genre: selectedGenre
            )
        } header: {
            Text("Genre & Color")
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save") {
                saveAnnotation()
            }
            .disabled(!canSave)
        }

        // Explicit keyboard toolbar replaces iOS's auto-injected Done button
        // for .numberPad fields, which appears but whose tap action is dropped
        // during constraint recovery (broken on iOS 18.2 and 26.1).
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button {
                focusedField = nil
            } label: {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    @ViewBuilder
    private var textSelectionContent: some View {
        if let image = capturedImage, !detectedTextBlocks.isEmpty {
            TextSelectionView(
                capturedImage: image,
                textBlocks: detectedTextBlocks,
                onConfirm: { selectedText in
                    insertOCRText(selectedText)
                    showingTextSelection = false
                },
                onCancel: {
                    showingTextSelection = false
                    detectedTextBlocks = []
                    capturedImage = nil
                }
            )
        } else {
            Color.clear
                .onAppear {
                    showingTextSelection = false
                }
        }
    }
    
    @ViewBuilder
    private var ocrProcessingOverlay: some View {
        if isProcessingOCR {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    Text("Recognizing text...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(32)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Methods
    
    private func saveAnnotation() {
        guard let page = Int(pageNumber) else { return }
        
        // Encode formatting data
        let encodedFormattingData = try? JSONEncoder().encode(formattingData)
        
        if let existingAnnotation = annotation {
            existingAnnotation.text = text
            existingAnnotation.pageNumber = page
            existingAnnotation.personalNotes = personalNotes.isEmpty ? nil : personalNotes
            existingAnnotation.genre = selectedGenre.rawValue
            existingAnnotation.color = selectedColor
            existingAnnotation.formattingData = encodedFormattingData
            existingAnnotation.dateModified = Date()
            
        } else {
            let newAnnotation = Annotation(
                text: text,
                pageNumber: page,
                personalNotes: personalNotes.isEmpty ? nil : personalNotes,
                color: selectedColor,
                genre: selectedGenre,
                formattingData: encodedFormattingData,
                book: book
            )
            
            book.annotations.append(newAnnotation)
            modelContext.insert(newAnnotation)
            
        }
        
        dismiss()
    }
    
    // MARK: - OCR Methods
    
    private func checkCameraPermission() {
        let status = CameraPermissionManager.checkPermission()
        // Button should be enabled if authorized OR not yet determined (first launch)
        cameraPermissionGranted = (status == .authorized || status == .notDetermined)
        
    }
    
    private func handleCameraButtonTap() {
        let status = CameraPermissionManager.checkPermission()
        
        switch status {
        case .authorized:
            if hideOCRWarning {
                showingCamera = true
            } else {
                showingOCRWarning = true
            }
            
        case .notDetermined:
            CameraPermissionManager.requestPermission { granted in
                if granted {
                    cameraPermissionGranted = true
                    if hideOCRWarning {
                        showingCamera = true
                    } else {
                        showingOCRWarning = true
                    }
                } else {
                    showingPermissionAlert = true
                }
            }
            
        case .denied, .restricted:
            showingPermissionAlert = true
        }
    }
    
    private func processImageWithOCR(_ image: UIImage) {
        isProcessingOCR = true
        
        Task {
            let blocks = await OCRTextRecognizer.recognizeText(from: image)
            
            
            await MainActor.run {
                isProcessingOCR = false
                
                if blocks.isEmpty {
                    ocrError = "No text found in image. Try better lighting, hold the camera steady, or type the text manually."
                    showingOCRError = true
                    capturedImage = nil
                } else {
                    detectedTextBlocks = blocks
                    showingTextSelection = true
                }
            }
        }
    }
    
    private func insertOCRText(_ ocrText: String) {
        if text.isEmpty {
            text = ocrText
        } else {
            let trimmedExisting = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedNew = ocrText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            text = trimmedExisting + " " + trimmedNew
        }
        
        capturedImage = nil
        detectedTextBlocks = []
        
    }
}
