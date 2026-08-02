import SwiftUI
import UIKit

// MARK: - MarkdownEditorController

/// Bridges the keyboard-bar buttons to the UITextView so formatting commands
/// apply at the caret / selection instead of appending to the end.
@MainActor
final class MarkdownEditorController {
    weak var textView: UITextView?
    var syncText: ((String) -> Void)?

    func toggleInline(_ marker: String) {
        apply { MarkdownEditing.toggleInline($0, selection: $1, marker: marker) }
    }

    func setHeading(_ level: Int) {
        apply { MarkdownEditing.setHeading($0, selection: $1, level: level) }
    }

    func toggleBullet() {
        apply { MarkdownEditing.toggleBullet($0, selection: $1) }
    }

    private func apply(_ transform: (String, NSRange) -> MarkdownEdit) {
        guard let textView else { return }
        let edit = transform(textView.text, textView.selectedRange)
        MarkdownTextView.setText(edit.text, on: textView)
        textView.selectedRange = edit.selection
        syncText?(edit.text)
        if !textView.isFirstResponder { textView.becomeFirstResponder() }
    }
}

// MARK: - MarkdownTextView

/// UITextView-backed body editor. UIKit is required here: pre-iOS-18
/// `TextEditor` exposes no selection, so toolbar commands couldn't honour the
/// caret, and there is no hook to continue bullet lists on Return.
struct MarkdownTextView: UIViewRepresentable {
    @Binding var text: String
    let controller: MarkdownEditorController
    var minHeight: CGFloat = 360
    let keyboardBar: () -> EditorKeyboardBar

    static var attributes: [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 9
        return [
            .font: UIFont(name: "Inter Tight", size: 15) ?? .systemFont(ofSize: 15),
            .foregroundColor: UIColor(named: "noteInk") ?? .label,
            .paragraphStyle: paragraph
        ]
    }

    static func setText(_ string: String, on textView: UITextView) {
        textView.attributedText = NSAttributedString(string: string, attributes: attributes)
        textView.typingAttributes = attributes
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.tintColor = UIColor(named: "noteInk")
        Self.setText(text, on: textView)

        // SwiftUI's .toolbar(placement: .keyboard) doesn't attach to UIKit
        // first responders, so the bar rides in as an input accessory view.
        let host = UIHostingController(rootView: keyboardBar())
        host.view.backgroundColor = .clear
        host.view.frame = CGRect(x: 0, y: 0, width: 0, height: 44)
        host.view.autoresizingMask = .flexibleWidth
        textView.inputAccessoryView = host.view
        context.coordinator.accessoryHost = host

        controller.textView = textView
        controller.syncText = { [weak coordinator = context.coordinator] in
            coordinator?.parent.text = $0
        }
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        controller.textView = textView
        if textView.text != text {
            let selection = textView.selectedRange
            Self.setText(text, on: textView)
            let maxLocation = (text as NSString).length
            textView.selectedRange = NSRange(location: min(selection.location, maxLocation), length: 0)
        }
        context.coordinator.accessoryHost?.rootView = keyboardBar()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite, width > 0 else { return nil }
        let fit = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: max(fit.height, minHeight))
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: MarkdownTextView
        var accessoryHost: UIHostingController<EditorKeyboardBar>?

        init(_ parent: MarkdownTextView) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText replacement: String) -> Bool {
            guard replacement == "\n",
                  let edit = MarkdownEditing.returnKeyEdit(textView.text, selection: range) else { return true }
            MarkdownTextView.setText(edit.text, on: textView)
            textView.selectedRange = edit.selection
            parent.text = edit.text
            return false
        }
    }
}
