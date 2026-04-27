import XCTest
import SwiftData
@testable import NOTE

@MainActor
final class NoteModelTests: XCTestCase {

    private var container: ModelContainer!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Note.self, TodoItem.self, configurations: config)
    }

    override func tearDown() {
        container = nil
    }

    func test_noteInit_defaultValues() {
        let note = Note(title: "x")
        XCTAssertEqual(note.title, "x")
        XCTAssertEqual(note.body, "")
        XCTAssertEqual(note.tags, [])
        XCTAssertEqual(note.todos.count, 0)
    }

    func test_deletingNote_cascadesToTodos() throws {
        let ctx = container.mainContext

        let todo1 = TodoItem(text: "one")
        let todo2 = TodoItem(text: "two")
        let note = Note(title: "with todos", todos: [todo1, todo2])
        ctx.insert(note)
        try ctx.save()

        // Sanity: todos are queryable.
        var allTodos = try ctx.fetch(FetchDescriptor<TodoItem>())
        XCTAssertEqual(allTodos.count, 2)

        ctx.delete(note)
        try ctx.save()

        // Cascade: deleting the note removes its todos.
        allTodos = try ctx.fetch(FetchDescriptor<TodoItem>())
        XCTAssertEqual(allTodos.count, 0, "Expected cascade-delete on Note.todos")

        let allNotes = try ctx.fetch(FetchDescriptor<Note>())
        XCTAssertEqual(allNotes.count, 0)
    }

    func test_independentNotes_doNotCascadeIntoEachOther() throws {
        let ctx = container.mainContext

        let a = Note(title: "a", todos: [TodoItem(text: "a1")])
        let b = Note(title: "b", todos: [TodoItem(text: "b1")])
        ctx.insert(a)
        ctx.insert(b)
        try ctx.save()

        ctx.delete(a)
        try ctx.save()

        let remainingNotes = try ctx.fetch(FetchDescriptor<Note>())
        XCTAssertEqual(remainingNotes.count, 1)
        XCTAssertEqual(remainingNotes.first?.title, "b")

        let remainingTodos = try ctx.fetch(FetchDescriptor<TodoItem>())
        XCTAssertEqual(remainingTodos.count, 1)
        XCTAssertEqual(remainingTodos.first?.text, "b1")
    }
}
