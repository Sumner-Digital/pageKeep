//
//  OCRTextRecognizer.swift
//  PageKeep
//
//  Created on November 4, 2025
//  Phase 6: Camera & OCR Implementation
//  Updated: Sentence-based detection - No Y-sorting
//

import Foundation
import Vision
import UIKit
import NaturalLanguage

// MARK: - Text Block Data Structure

/// Represents a detected block of text from OCR
/// Each block contains the recognized text, its position, and confidence level
struct TextBlock: Identifiable, Equatable {
    let id: UUID
    let text: String
    let boundingBox: CGRect  // Normalized coordinates (0.0 to 1.0)
    let confidence: Float    // Recognition confidence (0.0 to 1.0)
    
    init(id: UUID = UUID(), text: String, boundingBox: CGRect, confidence: Float) {
        self.id = id
        self.text = text
        self.boundingBox = boundingBox
        self.confidence = confidence
    }
    
    // MARK: - Equatable Conformance
    static func == (lhs: TextBlock, rhs: TextBlock) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - OCR Text Recognizer

/// Handles optical character recognition (OCR) using Apple's Vision framework
/// Converts images of book pages into machine-readable text
class OCRTextRecognizer {
    
    // MARK: - Recognition Configuration
    
    /// Recognition accuracy level - .accurate is slower but more precise
    private static let recognitionLevel: VNRequestTextRecognitionLevel = .accurate
    
    /// Supported languages for text recognition
    private static let supportedLanguages = ["en-US"]
    
    // MARK: - Public Methods
    
    /// Recognizes text from an image and returns sentence-based text blocks
    /// - Parameter image: The image to perform OCR on (typically a photo of a book page)
    /// - Returns: Array of TextBlock objects, each containing one sentence
    static func recognizeText(from image: UIImage) async -> [TextBlock] {
        // Convert UIImage to CGImage (required by Vision framework)
        guard let cgImage = image.cgImage else {
            
            return []
        }
        
        // Create the text recognition request
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = recognitionLevel
        request.recognitionLanguages = supportedLanguages
        request.usesLanguageCorrection = true
        
        // Create a request handler with the image
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Perform the OCR request
        do {
            try requestHandler.perform([request])
        } catch {
            
            return []
        }
        
        // Extract results from the request
        guard let observations = request.results else {
            
            return []
        }
        
        // Convert Vision observations to raw TextBlocks
        // Keep Vision's natural detection order - don't sort by Y-coordinate
        var rawBlocks: [TextBlock] = []
        var totalConfidence: Float = 0
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else {
                continue
            }
            
            let text = topCandidate.string
            let confidence = topCandidate.confidence
            let boundingBox = observation.boundingBox
            
            // Only include text blocks with reasonable confidence (>50%)
            guard confidence > 0.5 else {
                continue
            }
            
            rawBlocks.append(TextBlock(
                text: text,
                boundingBox: boundingBox,
                confidence: confidence
            ))
            totalConfidence += confidence
        }
        
       
        
        // Combine all text in Vision's natural order (no Y-sorting)
        let fullText = rawBlocks.map { $0.text }.joined(separator: " ")
        
        
        // Calculate average confidence
        let avgConfidence = rawBlocks.isEmpty ? 1.0 : totalConfidence / Float(rawBlocks.count)
        
        // Split into sentences
        let sentenceBlocks = splitIntoSentences(fullText: fullText, confidence: avgConfidence)
        
        
        
        return sentenceBlocks
    }
    
    // MARK: - Sentence Splitting
    
    /// Splits combined text into individual sentences using NLTokenizer
    /// - Parameters:
    ///   - fullText: The combined text from all OCR blocks
    ///   - confidence: Average confidence to assign to each sentence
    /// - Returns: Array of TextBlocks, one per sentence
    private static func splitIntoSentences(fullText: String, confidence: Float) -> [TextBlock] {
        guard !fullText.isEmpty else { return [] }
        
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = fullText
        
        var sentences: [TextBlock] = []
        
        tokenizer.enumerateTokens(in: fullText.startIndex..<fullText.endIndex) { range, _ in
            let sentence = String(fullText[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Only include non-empty sentences
            if !sentence.isEmpty {
                sentences.append(TextBlock(
                    text: sentence,
                    boundingBox: CGRect(x: 0, y: 0, width: 1, height: 0.05),
                    confidence: confidence
                ))
                
            }
            return true
        }
        
        return sentences
    }
    
    /// Concatenates text from multiple blocks into a single string
    /// - Parameter blocks: Array of TextBlock objects
    /// - Returns: Combined text string
    static func concatenateText(from blocks: [TextBlock]) -> String {
        guard !blocks.isEmpty else { return "" }
        
        // Join sentences with newlines for readability
        return blocks.map { $0.text }.joined(separator: "\n")
    }
}

