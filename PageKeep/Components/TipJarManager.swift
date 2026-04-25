//
//  TipJarManager.swift
//  PageKeep
//
//  Created on February 7, 2026
//  StoreKit 2 manager for tip jar purchases
//

import StoreKit
import Combine
import os.log

@MainActor
class TipJarManager: ObservableObject {
    
    @Published var products: [Product] = []
    @Published var purchaseState: PurchaseState = .idle
    
    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case success
        case failed(String)
    }
    
    private var transactionListener: Task<Void, Never>?
    
    private let productIDs = [
        "com.pagekeep.tip.coffee",
        "com.pagekeep.tip.latte",
        "com.pagekeep.tip.librarycard"
    ]
    
    // MARK: - Transaction Listener
    
    func startListening() {
        transactionListener = Task {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    await transaction.finish()
                    purchaseState = .success
                case .unverified(_, let error):
                    // Do not finish — let StoreKit retry. Surface so the bug isn't silent.
                    os_log("Unverified StoreKit transaction: %{public}@", type: .error, "\(error)")
                }
            }
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Fetch Products
    
    func fetchProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIDs)
            // Sort by price (lowest first)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async {
        purchaseState = .purchasing
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Finish the transaction
                    await transaction.finish()
                    purchaseState = .success
                case .unverified:
                    purchaseState = .failed("Purchase could not be verified.")
                }
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed("Purchase failed. Please try again.")
        }
    }
}
