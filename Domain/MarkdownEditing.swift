import Foundation

/// A text mutation produced by a formatting command: the full replacement
/// string plus the selection (UTF-16 range) the caret should end up in.
struct MarkdownEdit: Equatable {
    var text: String
    var selection: NSRange
}

/// Pure markdown-editing operations shared by the editor toolbar and the
/// return-key handler. All ranges are UTF-16 (`NSRange`), matching UITextView.
enum MarkdownEditing {

    static let bulletPrefix = "- "

    // MARK: - Inline (bold / italic)

    static func toggleInline(_ text: String, selection: NSRange, marker: String) -> MarkdownEdit {
        let ns = text as NSString
        var sel = clamp(selection, in: ns)
        let markerLen = (marker as NSString).length

        if sel.length == 0 {
            // No selection: wrap the word under the caret. With nothing to
            // wrap, insert a marker pair and park the caret inside.
            if let word = wordRange(at: sel.location, in: ns) {
                sel = word
            } else {
                let out = ns.replacingCharacters(in: sel, with: marker + marker)
                return MarkdownEdit(text: out, selection: NSRange(location: sel.location + markerLen, length: 0))
            }
        }

        let selected = ns.substring(with: sel)
        let selectedNS = selected as NSString

        // Selection already includes the markers → strip them. Skipped when
        // the selection starts a longer run (e.g. "**bold**" under an italic
        // toggle), where stripping one "*" would corrupt the bold pair.
        if selected.hasPrefix(marker), selected.hasSuffix(marker), selectedNS.length >= 2 * markerLen,
           !(marker == "*" && selected.hasPrefix("**")) {
            let inner = selectedNS.substring(with: NSRange(location: markerLen, length: selectedNS.length - 2 * markerLen))
            let out = ns.replacingCharacters(in: sel, with: inner)
            return MarkdownEdit(text: out, selection: NSRange(location: sel.location, length: (inner as NSString).length))
        }

        // Markers immediately surround the selection → strip those. Same
        // guard: an adjacent "*" that belongs to a "**" pair stays put, so
        // italicizing bold text yields "***word***" instead of eating stars.
        let before = NSRange(location: sel.location - markerLen, length: markerLen)
        let after = NSRange(location: NSMaxRange(sel), length: markerLen)
        if sel.location >= markerLen, NSMaxRange(after) <= ns.length,
           ns.substring(with: before) == marker, ns.substring(with: after) == marker,
           !(marker == "*" && (character("*", precedes: before, in: ns) || character("*", follows: after, in: ns))) {
            var out = ns.replacingCharacters(in: after, with: "")
            out = (out as NSString).replacingCharacters(in: before, with: "")
            return MarkdownEdit(text: out, selection: NSRange(location: sel.location - markerLen, length: sel.length))
        }

        let out = ns.replacingCharacters(in: sel, with: marker + selected + marker)
        return MarkdownEdit(text: out, selection: NSRange(location: sel.location + markerLen, length: sel.length))
    }

    // MARK: - Headings

    /// Sets `level` on the caret's line; same level again toggles it off.
    static func setHeading(_ text: String, selection: NSRange, level: Int) -> MarkdownEdit {
        let ns = text as NSString
        let sel = clamp(selection, in: ns)
        let lineRange = ns.lineRange(for: NSRange(location: sel.location, length: 0))
        let line = ns.substring(with: lineRange)
        let hasNewline = line.hasSuffix("\n")
        let content = hasNewline ? String(line.dropLast()) : line

        let existing = headingPrefix(of: content)
        let rest = String(content.dropFirst(existing.count))
        let target = String(repeating: "#", count: level) + " "
        let newPrefix = (existing == target) ? "" : target

        let newContent = newPrefix + rest
        let out = ns.replacingCharacters(in: lineRange, with: newContent + (hasNewline ? "\n" : ""))

        let delta = (newPrefix as NSString).length - (existing as NSString).length
        let minCaret = lineRange.location + (newPrefix as NSString).length
        let maxCaret = lineRange.location + (newContent as NSString).length
        let caret = min(max(sel.location + delta, minCaret), maxCaret)
        return MarkdownEdit(text: out, selection: NSRange(location: caret, length: 0))
    }

    // MARK: - Bullets

    /// Toggles `- ` on every line touched by the selection.
    static func toggleBullet(_ text: String, selection: NSRange) -> MarkdownEdit {
        let ns = text as NSString
        let sel = clamp(selection, in: ns)
        let lineRange = ns.lineRange(for: sel)
        let block = ns.substring(with: lineRange)
        let hasNewline = block.hasSuffix("\n")
        var lines = block.components(separatedBy: "\n")
        if hasNewline { lines.removeLast() }

        let removing = lines.contains { $0.hasPrefix(bulletPrefix) }
            && lines.allSatisfy { $0.hasPrefix(bulletPrefix) || $0.isEmpty }

        let newLines: [String]
        if removing {
            newLines = lines.map { $0.hasPrefix(bulletPrefix) ? String($0.dropFirst(bulletPrefix.count)) : $0 }
        } else if lines.count == 1 {
            newLines = [bulletPrefix + lines[0]]
        } else {
            newLines = lines.map { $0.isEmpty || $0.hasPrefix(bulletPrefix) ? $0 : bulletPrefix + $0 }
        }

        let newBlock = newLines.joined(separator: "\n") + (hasNewline ? "\n" : "")
        let out = ns.replacingCharacters(in: lineRange, with: newBlock)

        if sel.length == 0, lines.count == 1 {
            let delta = (newLines[0] as NSString).length - (lines[0] as NSString).length
            let minCaret = lineRange.location
            let maxCaret = lineRange.location + (newLines[0] as NSString).length
            let caret = min(max(sel.location + delta, minCaret), maxCaret)
            return MarkdownEdit(text: out, selection: NSRange(location: caret, length: 0))
        }
        let blockLen = (newBlock as NSString).length - (hasNewline ? 1 : 0)
        return MarkdownEdit(text: out, selection: NSRange(location: lineRange.location, length: blockLen))
    }

    // MARK: - Return key

    /// Handles Return inside a bullet list. `selection` is the range the
    /// newline would replace. Returns nil when default behavior is fine:
    /// a non-empty item continues the list, an empty item exits it.
    static func returnKeyEdit(_ text: String, selection: NSRange) -> MarkdownEdit? {
        let ns = text as NSString
        let sel = clamp(selection, in: ns)
        let lineRange = ns.lineRange(for: NSRange(location: sel.location, length: 0))
        let line = ns.substring(with: lineRange)
        let content = line.hasSuffix("\n") ? String(line.dropLast()) : line
        guard content.hasPrefix(bulletPrefix) else { return nil }

        let item = content.dropFirst(bulletPrefix.count)
        if item.trimmingCharacters(in: .whitespaces).isEmpty {
            guard sel.length == 0 else { return nil }
            let contentRange = NSRange(location: lineRange.location, length: (content as NSString).length)
            let out = ns.replacingCharacters(in: contentRange, with: "")
            return MarkdownEdit(text: out, selection: NSRange(location: lineRange.location, length: 0))
        }

        guard sel.location >= lineRange.location + (bulletPrefix as NSString).length else { return nil }
        let insert = "\n" + bulletPrefix
        let out = ns.replacingCharacters(in: sel, with: insert)
        return MarkdownEdit(text: out, selection: NSRange(location: sel.location + (insert as NSString).length, length: 0))
    }

    // MARK: - Helpers

    /// Expands a caret position to the alphanumeric word around it.
    private static func wordRange(at location: Int, in ns: NSString) -> NSRange? {
        func isWordChar(_ offset: Int) -> Bool {
            guard offset >= 0, offset < ns.length else { return false }
            guard let scalar = Unicode.Scalar(ns.character(at: offset)) else { return false }
            return CharacterSet.alphanumerics.contains(scalar)
        }
        var start = location
        var end = location
        while isWordChar(start - 1) { start -= 1 }
        while isWordChar(end) { end += 1 }
        guard end > start else { return nil }
        return NSRange(location: start, length: end - start)
    }

    private static func character(_ char: String, precedes range: NSRange, in ns: NSString) -> Bool {
        let offset = range.location - 1
        guard offset >= 0 else { return false }
        return ns.substring(with: NSRange(location: offset, length: 1)) == char
    }

    private static func character(_ char: String, follows range: NSRange, in ns: NSString) -> Bool {
        let offset = NSMaxRange(range)
        guard offset < ns.length else { return false }
        return ns.substring(with: NSRange(location: offset, length: 1)) == char
    }

    private static func headingPrefix(of line: String) -> String {
        guard let range = line.range(of: "^#{1,6} ", options: .regularExpression) else { return "" }
        return String(line[range])
    }

    private static func clamp(_ range: NSRange, in ns: NSString) -> NSRange {
        let location = max(0, min(range.location, ns.length))
        let length = max(0, min(range.length, ns.length - location))
        return NSRange(location: location, length: length)
    }
}
