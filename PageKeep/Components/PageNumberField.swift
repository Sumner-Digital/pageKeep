//
//  PageNumberField.swift
//  PageKeep
//
//  UIViewRepresentable wrapper for the Page Number input on Add Annotation.
//  Wraps a UITextField with keyboardType = .numberPad and gives it its
//  own UIToolbar inputAccessoryView whose Done item is the same
//  UIBarButtonItem(barButtonSystemItem: .done, ...) primitive used by
//  FormattedTextEditor.swift:69 and PersonalNotesEditor — so all three
//  keyboard accessories on Add Annotation render identically (iOS 26
//  styles the system Done item as a Liquid Glass blue circle with white
//  checkmark).
//
//  SwiftUI's ToolbarItemGroup(placement: .keyboard) renders differently
//  than the UIKit primitive on iOS 26, which is why this wrapper exists
//  rather than a plain SwiftUI TextField + SwiftUI keyboard toolbar.
//
//  The bug-fix rationale from Phase 4.2 still applies: iOS auto-injects
//  a broken Done on .numberPad fields when no explicit toolbar is set,
//  whose tap action is dropped during constraint recovery on iOS 18.2
//  and 26.1. The explicit toolbar here replaces that broken default.
//

import SwiftUI
import UIKit

struct PageNumberField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.keyboardType = .numberPad
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.text = text

        // Two-way bind text changes back to the SwiftUI binding.
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingChanged(_:)),
            for: .editingChanged
        )

        // Keyboard accessory — same UIBarButtonItem .done primitive used by
        // FormattedTextEditor and PersonalNotesEditor.
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: #selector(Coordinator.dismissKeyboard))
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar

        context.coordinator.textField = textField
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        if textField.text != text {
            textField.text = text
        }
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: PageNumberField
        weak var textField: UITextField?

        init(_ parent: PageNumberField) {
            self.parent = parent
        }

        @objc func dismissKeyboard() {
            textField?.resignFirstResponder()
        }

        @objc func editingChanged(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }
}
