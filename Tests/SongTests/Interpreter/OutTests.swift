import XCTest
import Song

class OutTests: XCTestCase {

    func testOut_characterValue_doesNotIncludeQuotes() {
        let char = Expression.char("A")
        let actual = char.out()
        XCTAssertEqual("A", actual)
    }

    func testOut_stringValue_doesNotIncludeQuotes() {
        let string = Expression.string("foo")
        let actual = string.out()
        XCTAssertEqual("foo", actual)
    }

    func testOut_closureValue_doesNotIncludeContext() {
        let subfunction = Subfunction(name: "foo", patterns: [], when: .bool(true), body: .int(99))
        let function = Expression.subfunction(subfunction)
        let context: Context = ["a": .int(5)]
        let string = Expression.closure("foo", [function], context)
        let actual = string.out()
        XCTAssertEqual("[foo() When Yes = 99]", actual)
    }

    func testOut_integerValue() {
        let string = Expression.int(5)
        let actual = string.out()
        XCTAssertEqual("5", actual)
    }

    func test_evaluate_noArguments_emptyString() {
        assertNoThrow {
            let call = Expression.call("out", [])
            XCTAssertEqual(Expression.string(""), try call.evaluate())
        }
    }

    func test_evaluate_oneArgument_descriptionOfArgument() {
        assertNoThrow {
            let call = Expression.call("out", [.int(99)])
            XCTAssertEqual(Expression.string("99"), try call.evaluate())
        }
    }

    func test_evaluate_multipleArguments_joinsWithSpace() {
        assertNoThrow {
            let call = Expression.call("out", [.int(99), .string("is in"), .list([.bool(true), .int(99)])])
            XCTAssertEqual(Expression.string("99 is in [Yes, 99]"), try call.evaluate())
        }
    }
}