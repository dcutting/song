import XCTest
import Song

class BooleanValueTests: XCTestCase {
    
    let trueBooleanValue = Expression.booleanValue(true)
    let falseBooleanValue = Expression.booleanValue(false)
    
    func testConstructor() {
        switch trueBooleanValue {
        case .booleanValue:
            XCTAssertTrue(true)
        default:
            XCTFail("not a boolean")
        }
    }
    
    func testDescriptionTrue() {
        let result = "\(trueBooleanValue)"
        XCTAssertEqual("yes", result)
    }
    
    func testDescriptionFalse() {
        let result = "\(falseBooleanValue)"
        XCTAssertEqual("no", result)
    }
    
    func testEvaluateTrue() {
        assertNoThrow {
            let result = try trueBooleanValue.evaluate()
            XCTAssertEqual(trueBooleanValue, result)
        }
    }
    
    func testEvaluateFalse() {
        assertNoThrow {
            let result = try falseBooleanValue.evaluate()
            XCTAssertEqual(falseBooleanValue, result)
        }
    }
}
