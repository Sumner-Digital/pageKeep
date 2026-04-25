//
//  SettingsView.swift
//  PageKeep
//
//  Created on February 6, 2026
//  Settings page with library management and app info
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var books: [Book]
    @Query private var annotations: [Annotation]
    
    @State private var showingClearConfirmation = false
    @State private var confirmationText = ""
    @State private var showingClearedSuccess = false
    @State private var showingPreClearConfirmation = false
    @State private var showingTipJar = false
    
    // OCR warning reset
    @AppStorage("hideOCRWarning") private var hideOCRWarning = false
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Library Stats
                Section {
                    HStack {
                        Text("Books")
                        Spacer()
                        Text("\(books.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Annotations")
                        Spacer()
                        Text("\(annotations.count)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Your Library")
                }
                
                // MARK: - Data Management
                Section {
                
                    
                    // Clear library
                    Button(role: .destructive) {
                        showingPreClearConfirmation = true
                    } label: {
                        Label("Clear Entire Library", systemImage: "trash")
                    }
                    .disabled(books.isEmpty)
                } header: {
                    Text("Data")
                }
                
                // MARK: - Preferences
                Section {
                    Toggle("Show OCR Camera Warning", isOn: Binding(
                        get: { !hideOCRWarning },
                        set: { hideOCRWarning = !$0 }
                    ))
                } header: {
                    Text("Preferences")
                }
                
                // MARK: - Support
                Section {
                    Button {
                        showingTipJar = true
                    } label: {
                        Label("Tip Jar", systemImage: "heart.fill")
                            .foregroundStyle(.pink)
                    }
                } header: {
                    Text("Support PageKeep")
                }
                
                // MARK: - About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Made with")
                        Spacer()
                        Text("☕️ & 📚")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About PageKeep")
                } footer: {
                    Text("Your reading data stays on your device. No accounts, no cloud sync, no tracking.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Are You Sure?", isPresented: $showingPreClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Continue", role: .destructive) {
                    showingClearConfirmation = true
                }
            } message: {
                Text("This will permanently delete all \(books.count) books and \(annotations.count) annotations from your library. This cannot be undone.")
            }
            .alert("Clear Entire Library", isPresented: $showingClearConfirmation) {
                TextField("Type DELETE to confirm", text: $confirmationText)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                Button("Cancel", role: .cancel) {
                    confirmationText = ""
                }
                Button("Clear Everything", role: .destructive) {
                    if confirmationText.uppercased() == "DELETE" {
                        clearLibrary()
                    }
                    confirmationText = ""
                }
            } message: {
                Text("This will permanently delete all \(books.count) books and \(annotations.count) annotations. This cannot be undone.\n\nType DELETE to confirm.")
            }
            .overlay {
                if showingClearedSuccess {
                    successHUD
                }
            }
            .sheet(isPresented: $showingTipJar) {
                TipJarView()
            }
        }
    }
    
    // MARK: - Success HUD
    
    private var successHUD: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
            Text("Library Cleared")
                .font(.headline)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showingClearedSuccess = false
                }
                dismiss()
            }
        }
    }
    
    // MARK: - Methods
    
    private func clearLibrary() {
        // Snapshot into local arrays to avoid @Query re-evaluation during deletion
        let allAnnotations = Array(annotations)
        let allBooks = Array(books)
        
        for annotation in allAnnotations {
            modelContext.delete(annotation)
        }
        for book in allBooks {
            modelContext.delete(book)
        }
        
        try? modelContext.save()
        dismiss()
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
