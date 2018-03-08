import XCTest
import Song

class LambdaParserTests: XCTestCase {

    func test_shouldParse() {
        "|x| x".makes(.function(Function(name: nil, patterns: [.name("x")], when: .bool(true), body: .name("x"))))
        "| x , y | x".makes(.function(Function(name: nil, patterns: [.name("x"), .name("y")], when: .bool(true), body: .name("x"))))
"""
 |
 x
 ,
 y
 |
 x
""".makes(.function(Function(name: nil, patterns: [.name("x"), .name("y")], when: .bool(true), body: .name("x"))))
        "|[x|xs], y| x".makes(.function(Function(name: nil, patterns: [.cons([.name("x")], .name("xs")), .name("y")], when: .bool(true), body: .name("x"))))
        "|_| 5".makes(.function(Function(name: nil, patterns: [.ignore], when: .bool(true), body: .int(5))))
        "|| 5".makes(.function(Function(name: nil, patterns: [], when: .bool(true), body: .int(5))))
    }
}