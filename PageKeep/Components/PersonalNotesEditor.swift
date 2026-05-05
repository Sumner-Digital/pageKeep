//
//  PersonalNotesEditor.swift
//  PageKeep
//
//  UIViewRepresentable wrapper for personal notes input.
//  Gives independent control over autocorrect (off) and spell-check (on)
//  that SwiftUI's TextField(axis: .vertical) can't separate.
//

import SwiftUI
import UIKit

struct PersonalNotesEditor: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        // The whole reason this wrapper exists:
        textView.autocapitalizationType = .sentences
        textView.autocorrectionType = .no
        textView.spellCheckingType = .yes

        // Initial state with placeholder handling
        if text.isEmpty {
            textView.text = placeholder
            textView.textColor = .placeholderText
        } else {
            textView.text = text
            textView.textColor = .label
        }

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        // Sync external text changes (e.g. when reopening an existing annotation)
        if textView.text != text && textView.textColor != .placeholderText {
            textView.text = text
        }

        // Restore placeholder if cleared externally and not focused
        if text.isEmpty && !textView.isFirstResponder && textView.textColor != .placeholderText {
            textView.text = placeholder
            textView.textColor = .placeholderText
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        let parent: PersonalNotesEditor

        init(_ parent: PersonalNotesEditor) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == .placeholderText {
                textView.text = ""
                textView.textColor = .label
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = .placeholderText
            }
        }

        func textViewDidChange(_ textView: UITextView) {
            if textView.textColor != .placeholderText {
                parent.text = textView.text
            }
        }
    }
}
