//
//  TipJarView.swift
//  PageKeep
//
//  Created on February 7, 2026
//  Tip jar UI for supporting the developer
//

import SwiftUI
import StoreKit

struct TipJarView: View {
    
    @StateObject private var tipManager = TipJarManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                // MARK: - Header
                VStack(spacing: 12) {
                    Text("☕️")
                        .font(.system(size: 60))
                    
                    Text("Support PageKeep")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("PageKeep is free with no ads or tracking. If you enjoy the app, a tip helps keep development going!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // MARK: - Tip Buttons
                if tipManager.products.isEmpty {
                    ProgressView("Loading tips...")
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(tipManager.products) { product in
                            tipButton(for: product)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // MARK: - Footer
                Text("Tips are one-time and non-refundable. Thank you for your support!")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
            }
            .navigationTitle("Tip Jar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                tipManager.startListening()
                await tipManager.fetchProducts()
            }
            .overlay {
                if tipManager.purchaseState == .success {
                    thankYouHUD
                }
            }
        }
    }
    
    // MARK: - Tip Button
    
    private func tipButton(for product: Product) -> some View {
        Button {
            Task {
                await tipManager.purchase(product)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName(for: product))
                        .font(.headline)
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(product.displayPrice)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(tipManager.purchaseState == .purchasing)
    }
    
    // MARK: - Display Names
    
    private func displayName(for product: Product) -> String {
        switch product.id {
        case "com.pagekeep.tip.coffee":
            return "☕️ Coffee"
        case "com.pagekeep.tip.latte":
            return "🥛 Latte"
        case "com.pagekeep.tip.librarycard":
            return "📚 Library Card"
        default:
            return product.displayName
        }
    }
    
    // MARK: - Thank You HUD
    
    private var thankYouHUD: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 44))
                .foregroundStyle(.pink)
            Text("Thank You!")
                .font(.headline)
            Text("Your support means a lot.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    tipManager.purchaseState = .idle
                }
            }
        }
    }
}
