import XCTest
import Song

class ClosureTests: XCTestCase {

    lazy var function = makeNamedFunction()

    let context: Context = ["x": .int(5), "y": .string("hi")]
    
    func test_description() {
        assertNoThrow {
            let closure = try function.evaluate(context: context)
            let result = "\(closure)"
            XCTAssertEqual("[(x: 5, y: \"hi\") [foo(a, b) = x]]", result)
        }
    }
    
    func test_evaluate() {
        assertNoThrow {
            let closure = try function.evaluate(context: context)
            XCTAssertEqual(closure, try closure.evaluate())
        }
    }

    private func makeNamedFunction() -> Expression {
        let function = Function(name: "foo",
                                patterns: [.name("a"), .name("b")],
                                when: .bool(true),
                                body: .name("x"))
        return .function(function)
    }
}
