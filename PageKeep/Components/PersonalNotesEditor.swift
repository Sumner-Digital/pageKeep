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
        let textView = WrappingTextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        // The whole reason this wrapper exists:
        textView.autocapitalizationType = .sentences
        textView.autocorrectionType = .no
        textView.spellCheckingType = .yes

        // Word-wrap long lines at the text view's width instead of letting
        // the content grow horizontally past the right edge.
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.lineBreakMode = .byWordWrapping

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

/// UITextView subclass that pins its text container's wrap width to the
/// view's actual rendered width on every layout pass. Fixes long-line
/// overflow that earlier defenses (`widthTracksTextView`,
/// `lineBreakMode = .byWordWrapping`, SwiftUI `.frame(maxWidth: .infinity)`)
/// did not catch on their own — `updateUIView` is not called for layout-only
/// changes (rotation, keyboard show/hide, dynamic type), but
/// `layoutSubviews` runs on every layout pass.
private final class WrappingTextView: UITextView {
    override func layoutSubviews() {
        super.layoutSubviews()
        textContainer.size = CGSize(
            width: bounds.width,
            height: .greatestFiniteMagnitude
        )
    }
}
