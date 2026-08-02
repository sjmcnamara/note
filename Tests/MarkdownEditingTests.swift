import XCTest
@testable import NOTE

final class MarkdownEditingTests: XCTestCase {

    private func caret(_ location: Int) -> NSRange { NSRange(location: location, length: 0) }

    // MARK: - Return key (bullet continuation)

    func test_return_onBulletItem_continuesList() {
        let text = "- first"
        let edit = MarkdownEditing.returnKeyEdit(text, selection: caret(7))
        XCTAssertEqual(edit?.text, "- first\n- ")
        XCTAssertEqual(edit?.selection, caret(10))
    }

    func test_return_onEmptyBulletItem_exitsList() {
        let text = "- first\n- "
        let edit = MarkdownEditing.returnKeyEdit(text, selection: caret(10))
        XCTAssertEqual(edit?.text, "- first\n")
        XCTAssertEqual(edit?.selection, caret(8))
    }

    func test_return_onPlainLine_usesDefaultBehavior() {
        XCTAssertNil(MarkdownEditing.returnKeyEdit("plain text", selection: caret(10)))
    }

    func test_return_midItem_splitsIntoTwoItems() {
        let text = "- one two"
        let edit = MarkdownEditing.returnKeyEdit(text, selection: caret(5))
        XCTAssertEqual(edit?.text, "- one\n-  two")
        XCTAssertEqual(edit?.selection, caret(8))
    }

    func test_return_caretInsideBulletPrefix_usesDefaultBehavior() {
        XCTAssertNil(MarkdownEditing.returnKeyEdit("- first", selection: caret(1)))
    }

    func test_return_onMiddleListItem_continuesList() {
        let text = "- one\n- two\nplain"
        let edit = MarkdownEditing.returnKeyEdit(text, selection: caret(11))
        XCTAssertEqual(edit?.text, "- one\n- two\n- \nplain")
        XCTAssertEqual(edit?.selection, caret(14))
    }

    // MARK: - Inline (bold / italic)

    func test_bold_wrapsSelection() {
        let edit = MarkdownEditing.toggleInline("make this bold", selection: NSRange(location: 10, length: 4), marker: "**")
        XCTAssertEqual(edit.text, "make this **bold**")
        XCTAssertEqual(edit.selection, NSRange(location: 12, length: 4))
    }

    func test_bold_emptySelection_insertsMarkerPairWithCaretInside() {
        let edit = MarkdownEditing.toggleInline("note: ", selection: caret(6), marker: "**")
        XCTAssertEqual(edit.text, "note: ****")
        XCTAssertEqual(edit.selection, caret(8))
    }

    func test_bold_caretInsideWord_wrapsWholeWord() {
        let edit = MarkdownEditing.toggleInline("hello world", selection: caret(8), marker: "**")
        XCTAssertEqual(edit.text, "hello **world**")
        XCTAssertEqual(edit.selection, NSRange(location: 8, length: 5))
    }

    func test_italic_caretInsideWord_wrapsWholeWord() {
        let edit = MarkdownEditing.toggleInline("hello world", selection: caret(2), marker: "*")
        XCTAssertEqual(edit.text, "*hello* world")
        XCTAssertEqual(edit.selection, NSRange(location: 1, length: 5))
    }

    func test_italic_caretInsideItalicWord_unwraps() {
        let edit = MarkdownEditing.toggleInline("*hello* world", selection: caret(3), marker: "*")
        XCTAssertEqual(edit.text, "hello world")
        XCTAssertEqual(edit.selection, NSRange(location: 0, length: 5))
    }

    func test_italic_onBoldSelection_addsThirdStar() {
        let edit = MarkdownEditing.toggleInline("**word**", selection: NSRange(location: 2, length: 4), marker: "*")
        XCTAssertEqual(edit.text, "***word***")
        XCTAssertEqual(edit.selection, NSRange(location: 3, length: 4))
    }

    func test_italic_caretInsideBoldWord_addsThirdStar() {
        let edit = MarkdownEditing.toggleInline("**word**", selection: caret(4), marker: "*")
        XCTAssertEqual(edit.text, "***word***")
        XCTAssertEqual(edit.selection, NSRange(location: 3, length: 4))
    }

    func test_bold_onBoldItalicSelection_removesBoldKeepsItalic() {
        let edit = MarkdownEditing.toggleInline("***word***", selection: NSRange(location: 3, length: 4), marker: "**")
        XCTAssertEqual(edit.text, "*word*")
        XCTAssertEqual(edit.selection, NSRange(location: 1, length: 4))
    }

    func test_bold_selectionIncludingMarkers_unwraps() {
        let edit = MarkdownEditing.toggleInline("x **bold** y", selection: NSRange(location: 2, length: 8), marker: "**")
        XCTAssertEqual(edit.text, "x bold y")
        XCTAssertEqual(edit.selection, NSRange(location: 2, length: 4))
    }

    func test_bold_selectionSurroundedByMarkers_unwraps() {
        let edit = MarkdownEditing.toggleInline("x **bold** y", selection: NSRange(location: 4, length: 4), marker: "**")
        XCTAssertEqual(edit.text, "x bold y")
        XCTAssertEqual(edit.selection, NSRange(location: 2, length: 4))
    }

    func test_italic_wrapsSelection() {
        let edit = MarkdownEditing.toggleInline("lean in", selection: NSRange(location: 0, length: 4), marker: "*")
        XCTAssertEqual(edit.text, "*lean* in")
        XCTAssertEqual(edit.selection, NSRange(location: 1, length: 4))
    }

    // MARK: - Headings

    func test_h1_prefixesCaretLine() {
        let edit = MarkdownEditing.setHeading("title\nbody", selection: caret(3), level: 1)
        XCTAssertEqual(edit.text, "# title\nbody")
        XCTAssertEqual(edit.selection, caret(5))
    }

    func test_h2_onExistingH1_replacesPrefix() {
        let edit = MarkdownEditing.setHeading("# title", selection: caret(7), level: 2)
        XCTAssertEqual(edit.text, "## title")
        XCTAssertEqual(edit.selection, caret(8))
    }

    func test_h1_onExistingH1_togglesOff() {
        let edit = MarkdownEditing.setHeading("# title", selection: caret(7), level: 1)
        XCTAssertEqual(edit.text, "title")
        XCTAssertEqual(edit.selection, caret(5))
    }

    func test_heading_appliesToSecondLine_notEndOfText() {
        let edit = MarkdownEditing.setHeading("one\ntwo\nthree", selection: caret(5), level: 2)
        XCTAssertEqual(edit.text, "one\n## two\nthree")
        XCTAssertEqual(edit.selection, caret(8))
    }

    // MARK: - Bullets

    func test_bullet_prefixesCaretLine() {
        let edit = MarkdownEditing.toggleBullet("item", selection: caret(4))
        XCTAssertEqual(edit.text, "- item")
        XCTAssertEqual(edit.selection, caret(6))
    }

    func test_bullet_onEmptyText_insertsPrefix() {
        let edit = MarkdownEditing.toggleBullet("", selection: caret(0))
        XCTAssertEqual(edit.text, "- ")
        XCTAssertEqual(edit.selection, caret(2))
    }

    func test_bullet_onBulletedLine_togglesOff() {
        let edit = MarkdownEditing.toggleBullet("- item", selection: caret(6))
        XCTAssertEqual(edit.text, "item")
        XCTAssertEqual(edit.selection, caret(4))
    }

    func test_bullet_multiLineSelection_bulletsAllLines() {
        let text = "one\ntwo\nthree"
        let edit = MarkdownEditing.toggleBullet(text, selection: NSRange(location: 0, length: 13))
        XCTAssertEqual(edit.text, "- one\n- two\n- three")
        XCTAssertEqual(edit.selection, NSRange(location: 0, length: 19))
    }

    func test_bullet_multiLineAllBulleted_removesAll() {
        let text = "- one\n- two"
        let edit = MarkdownEditing.toggleBullet(text, selection: NSRange(location: 0, length: 11))
        XCTAssertEqual(edit.text, "one\ntwo")
        XCTAssertEqual(edit.selection, NSRange(location: 0, length: 7))
    }

    func test_bullet_appliesToCaretLine_notEndOfText() {
        let edit = MarkdownEditing.toggleBullet("one\ntwo", selection: caret(1))
        XCTAssertEqual(edit.text, "- one\ntwo")
        XCTAssertEqual(edit.selection, caret(3))
    }
}
