//
//  FormattedTextEditor.swift
//  PageKeep
//
//  Created by Allie Sumner on 10/24/25.
//  FIXED: Formatting inheritance bug resolved on 10/30/25 - Version 5
//

// UIViewRepresentable wrapper for UITextView with text formatting support
// Supports underline and strikethrough formatting with selection-based UI
// FIXED: Added auto-focus support for keyboard
// FIXED: Proper typing attributes management to prevent unwanted formatting inheritance
// VERSION 5: Tracks text changes and adjusts formatting ranges dynamically

import SwiftUI
import UIKit

struct FormattedTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var formattingData: TextFormattingData
    let placeholder: String
    var autoFocus: Bool = false
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.isScrollEnabled = true
        textView.autocapitalizationType = .sentences
        textView.autocorrectionType = .no
        textView.spellCheckingType = .yes

        // Store textView reference in coordinator
        context.coordinator.textView = textView
        
        // Add formatting toolbar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let underlineButton = UIBarButtonItem(
            image: UIImage(systemName: "underline"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.toggleUnderline)
        )
        
        let strikethroughButton = UIBarButtonItem(
            image: UIImage(systemName: "strikethrough"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.toggleStrikethrough)
        )
        
        let clearFormattingButton = UIBarButtonItem(
            title: "Clear Format",
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.clearAllFormatting)
        )
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: #selector(Coordinator.dismissKeyboard))
        
        toolbar.items = [underlineButton, strikethroughButton, flexSpace, clearFormattingButton, doneButton]
        textView.inputAccessoryView = toolbar
        
        // Store buttons for state updates
        context.coordinator.underlineButton = underlineButton
        context.coordinator.strikethroughButton = strikethroughButton
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        // Handle auto-focus
        if autoFocus && !textView.isFirstResponder {
            DispatchQueue.main.async {
                textView.becomeFirstResponder()
            }
        }
        
        // Only update if text changed externally
        if textView.text != text {
            let attributedText = NSMutableAttributedString(string: text)
            attributedText.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .body), range: NSRange(location: 0, length: text.count))
            attributedText.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: text.count))
            
            // Apply underline formatting
            for range in formattingData.underlineRanges {
                if let nsRange = range.toNSRange(in: text) {
                    attributedText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
                }
            }
            
            // Apply strikethrough formatting
            for range in formattingData.strikethroughRanges {
                if let nsRange = range.toNSRange(in: text) {
                    attributedText.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
                }
            }
            
            let selectedRange = textView.selectedRange
            textView.attributedText = attributedText
            textView.selectedRange = selectedRange
        }
        
        // Update placeholder appearance
        if text.isEmpty && !textView.isFirstResponder {
            textView.text = placeholder
            textView.textColor = .placeholderText
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: FormattedTextEditor
        var textView: UITextView?
        var underlineButton: UIBarButtonItem?
        var strikethroughButton: UIBarButtonItem?
        var isFixingAttributes = false
        var lastTextLength = 0
        
        init(_ parent: FormattedTextEditor) {
            self.parent = parent
            super.init()
            self.lastTextLength = parent.text.count
        }
        
        func textViewDidChange(_ textView: UITextView) {
            guard !isFixingAttributes else { return }
            
            let currentText = textView.text ?? ""
            let currentLength = currentText.count
            let lengthDifference = currentLength - lastTextLength
            
            // Update last length for next time
            defer { lastTextLength = currentLength }
            
            // If text length changed, we need to adjust formatting ranges
            if lengthDifference != 0 {
                adjustFormattingRanges(for: lengthDifference, in: textView)
            }
            
            // Update parent text
            if textView.textColor != .placeholderText {
                parent.text = currentText
            }
            
            // Update formatting data text length
            parent.formattingData.textLength = currentLength
            
            // Fix any incorrectly formatted text
            fixAttributesIfNeeded(in: textView)
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            updateToolbarButtons(for: textView)
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == .placeholderText {
                textView.text = ""
                textView.textColor = .label
                textView.font = UIFont.preferredFont(forTextStyle: .body)
            }
            lastTextLength = textView.text.count
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = .placeholderText
            }
        }
        
        // MARK: - Adjust Formatting Ranges
        
        private func adjustFormattingRanges(for lengthDifference: Int, in textView: UITextView) {
            // Get cursor position (where the change happened)
            let changePosition = textView.selectedRange.location - max(0, lengthDifference)
            
            // Adjust underline ranges
            parent.formattingData.underlineRanges = parent.formattingData.underlineRanges.compactMap { range in
                adjustRange(range, forChangeAt: changePosition, lengthDifference: lengthDifference)
            }
            
            // Adjust strikethrough ranges
            parent.formattingData.strikethroughRanges = parent.formattingData.strikethroughRanges.compactMap { range in
                adjustRange(range, forChangeAt: changePosition, lengthDifference: lengthDifference)
            }
        }
        
        private func adjustRange(_ range: TextRange, forChangeAt position: Int, lengthDifference: Int) -> TextRange? {
            // If change is after the range, no adjustment needed
            if position >= range.end {
                return range
            }
            
            // If change is before the range, shift the entire range
            if position <= range.start {
                let newStart = max(0, range.start + lengthDifference)
                let newEnd = max(0, range.end + lengthDifference)
                
                // If range becomes invalid (negative or zero length), remove it
                guard newEnd > newStart else { return nil }
                
                return TextRange(start: newStart, end: newEnd)
            }
            
            // If change is inside the range
            if lengthDifference > 0 {
                // Text added inside: expand the range
                return TextRange(start: range.start, end: range.end + lengthDifference)
            } else {
                // Text deleted inside: shrink the range
                let newEnd = max(range.start + 1, range.end + lengthDifference)
                return TextRange(start: range.start, end: newEnd)
            }
        }
        
        // MARK: - Fix Attributes After Insertion
        
        private func fixAttributesIfNeeded(in textView: UITextView) {
            isFixingAttributes = true
            defer { isFixingAttributes = false }
            
            let currentText = textView.text ?? ""
            guard !currentText.isEmpty else { return }
            
            let currentAttributedText = textView.attributedText ?? NSAttributedString(string: currentText)
            let mutableText = NSMutableAttributedString(attributedString: currentAttributedText)
            
            // Go through entire text and fix formatting
            let fullRange = NSRange(location: 0, length: currentText.count)
            
            // First, remove all formatting attributes
            mutableText.removeAttribute(.underlineStyle, range: fullRange)
            mutableText.removeAttribute(.strikethroughStyle, range: fullRange)
            
            // Ensure base attributes
            mutableText.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .body), range: fullRange)
            mutableText.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)
            
            // Re-apply only the formatting that should be there
            for range in parent.formattingData.underlineRanges {
                if let nsRange = range.toNSRange(in: currentText) {
                    mutableText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
                }
            }
            
            for range in parent.formattingData.strikethroughRanges {
                if let nsRange = range.toNSRange(in: currentText) {
                    mutableText.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
                }
            }
            
            // Update the text view if anything changed
            let selectedRange = textView.selectedRange
            textView.attributedText = mutableText
            textView.selectedRange = selectedRange
        }
        
        @objc func toggleUnderline() {
            guard let textView = textView,
                  textView.selectedRange.length > 0 else { return }
            
            let range = textView.selectedRange
            if let textRange = TextRange(nsRange: range, in: parent.text) {
                parent.formattingData.toggleUnderline(for: textRange)
                fixAttributesIfNeeded(in: textView)
                updateToolbarButtons(for: textView)
                
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
        }
        
        @objc func toggleStrikethrough() {
            guard let textView = textView,
                  textView.selectedRange.length > 0 else { return }
            
            let range = textView.selectedRange
            if let textRange = TextRange(nsRange: range, in: parent.text) {
                parent.formattingData.toggleStrikethrough(for: textRange)
                fixAttributesIfNeeded(in: textView)
                updateToolbarButtons(for: textView)
                
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
        }
        
        @objc func clearAllFormatting() {
            parent.formattingData.underlineRanges.removeAll()
            parent.formattingData.strikethroughRanges.removeAll()
            
            if let textView = textView {
                fixAttributesIfNeeded(in: textView)
                updateToolbarButtons(for: textView)
                
                let success = UINotificationFeedbackGenerator()
                success.notificationOccurred(.success)
            }
        }
        
        @objc func dismissKeyboard() {
            textView?.resignFirstResponder()
        }
        
        private func updateToolbarButtons(for textView: UITextView) {
            let range = textView.selectedRange
            
            guard range.length > 0,
                  let textRange = TextRange(nsRange: range, in: parent.text) else {
                underlineButton?.tintColor = .systemBlue
                strikethroughButton?.tintColor = .systemBlue
                return
            }
            
            let isUnderlined = parent.formattingData.underlineRanges.contains { $0.overlaps(textRange) }
            underlineButton?.tintColor = isUnderlined ? .systemGreen : .systemBlue
            
            let isStrikethrough = parent.formattingData.strikethroughRanges.contains { $0.overlaps(textRange) }
            strikethroughButton?.tintColor = isStrikethrough ? .systemGreen : .systemBlue
        }
    }
}

// MARK: - Text Formatting Data Model

struct TextFormattingData: Codable {
    var underlineRanges: [TextRange] = []
    var strikethroughRanges: [TextRange] = []
    var textLength: Int = 0
    
    mutating func toggleUnderline(for range: TextRange) {
        if let index = underlineRanges.firstIndex(where: { $0.overlaps(range) }) {
            underlineRanges.remove(at: index)
        } else {
            underlineRanges.append(range)
            underlineRanges = TextRange.merge(underlineRanges)
        }
    }
    
    mutating func toggleStrikethrough(for range: TextRange) {
        if let index = strikethroughRanges.firstIndex(where: { $0.overlaps(range) }) {
            strikethroughRanges.remove(at: index)
        } else {
            strikethroughRanges.append(range)
            strikethroughRanges = TextRange.merge(strikethroughRanges)
        }
    }
    
    mutating func clearAllFormatting() {
        underlineRanges.removeAll()
        strikethroughRanges.removeAll()
    }
}

struct TextRange: Codable, Equatable {
    let start: Int
    let end: Int
    
    init(start: Int, end: Int) {
        self.start = min(start, end)
        self.end = max(start, end)
    }
    
    init?(nsRange: NSRange, in text: String) {
        guard nsRange.location != NSNotFound,
              nsRange.location >= 0,
              nsRange.location + nsRange.length <= text.count else { return nil }
        self.start = nsRange.location
        self.end = nsRange.location + nsRange.length
    }
    
    func toNSRange(in text: String) -> NSRange? {
        guard start >= 0, end <= text.count, start <= end else { return nil }
        return NSRange(location: start, length: end - start)
    }
    
    func overlaps(_ other: TextRange) -> Bool {
        return start < other.end && end > other.start
    }
    
    static func merge(_ ranges: [TextRange]) -> [TextRange] {
        guard !ranges.isEmpty else { return [] }
        
        let sorted = ranges.sorted { $0.start < $1.start }
        var merged: [TextRange] = []
        var current = sorted[0]
        
        for range in sorted.dropFirst() {
            if current.end >= range.start {
                current = TextRange(start: current.start, end: max(current.end, range.end))
            } else {
                merged.append(current)
                current = range
            }
        }
        merged.append(current)
        
        return merged
    }
}
