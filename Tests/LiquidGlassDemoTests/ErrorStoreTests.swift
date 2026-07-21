import Testing
@testable import LiquidGlassDemo

@Suite struct ErrorStoreTests {
    @MainActor
    @Test func presentShowsAndDismissClears() {
        let errors = ErrorStore()
        #expect(errors.current == nil)
        errors.present(title: "Launch at Login", message: "registration failed")
        #expect(errors.current?.title == "Launch at Login")
        #expect(errors.current?.message == "registration failed")
        errors.dismiss()
        #expect(errors.current == nil)
    }

    @MainActor
    @Test func latestPresentationWins() {
        let errors = ErrorStore()
        errors.present(title: "First", message: "a")
        errors.present(title: "Second", message: "b")
        #expect(errors.current?.title == "Second")
    }
}
