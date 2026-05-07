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
        // Scroll enabled so the SwiftUI .frame on the wrapper is the source
        // of truth for size — matches FormattedTextEditor and lets long
        // lines wrap correctly at the right edge.
        textView.isScrollEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        // The whole reason this wrapper exists:
        textView.autocapitalizationType = .sentences
        textView.autocorrectionType = .no
        textView.spellCheckingType = .yes

        // Keyboard accessory: filled blue circle with a white checkmark,
        // right-aligned. Matches Page Number's SwiftUI .glassProminent
        // visual (solid blue circle, light checkmark) so the two
        // accessories read as siblings rather than cousins. UIKit's
        // closest equivalent is a UIButton with a filled configuration
        // and capsule corner style at equal width/height.
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.baseBackgroundColor = .systemBlue
        buttonConfig.baseForegroundColor = .white
        buttonConfig.cornerStyle = .capsule
        buttonConfig.image = UIImage(systemName: "checkmark")
        let button = UIButton(configuration: buttonConfig)
        button.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.dismissKeyboard),
            for: .touchUpInside
        )

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(customView: button)
        toolbar.items = [flexSpace, doneButton]
        textView.inputAccessoryView = toolbar

        // Stash the textView reference so the coordinator's dismissKeyboard
        // can resign it.
        context.coordinator.textView = textView

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
        weak var textView: UITextView?

        init(_ parent: PersonalNotesEditor) {
            self.parent = parent
        }

        @objc func dismissKeyboard() {
            textView?.resignFirstResponder()
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
