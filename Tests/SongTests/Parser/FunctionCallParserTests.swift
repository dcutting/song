import XCTest
import Song

class FunctionCallParserTests: XCTestCase {

    func test() {
        "1.inc".makes(.call("inc", [.int(1)]))
        "x.inc".makes(.call("inc", [.variable("x")]))
        "1.inc()".makes(.call("inc", [.int(1)]))
        "1.inc.foo".makes(.call("foo", [.call("inc", [.int(1)])]))
        "1.inc.foo()".makes(.call("foo", [.call("inc", [.int(1)])]))
        "1.inc().foo".makes(.call("foo", [.call("inc", [.int(1)])]))
        "1.inc().foo()".makes(.call("foo", [.call("inc", [.int(1)])]))
        "foo().inc".makes(.call("inc", [.call("foo", [])]))
        "foo()().inc".makes(.call("inc", [.callAnon(.call("foo", []), [])]))
        "foo().bar()".makes(.call("bar", [.call("foo", [])]))
        "(5).foo.bar".makes(.call("bar", [.call("foo", [.int(5)])]))
        "(5.foo).bar".makes(.call("bar", [.call("foo", [.int(5)])]))
        "(5.foo)(4)".makes(.callAnon(.call("foo", [.int(5)]), [.int(4)]))
        "5.(foo).bar".makes(.call("bar", [.callAnon(.variable("foo"), [.int(5)])]))
        "5.(foo.bar)".makes(.callAnon(.call("bar", [.variable("foo")]), [.int(5)]))
        "(||5)()".makes(.callAnon(.lambda([], .int(5)), []))
        "(|x|x)(1)".makes(.callAnon(.lambda([.variable("x")], .variable("x")), [.int(1)]))
        "(|x|x)(1)(2)".makes(.callAnon(.callAnon(.lambda([.variable("x")], .variable("x")), [.int(1)]), [.int(2)]))
        "(|x|x)(1)(2).foo".makes(.call("foo", [.callAnon(.callAnon(.lambda([.variable("x")], .variable("x")), [.int(1)]), [.int(2)])]))
        "1.(|x|x)".makes(.callAnon(.lambda([.variable("x")], .variable("x")), [.int(1)]))
        "(foo)()".makes(.callAnon(.variable("foo"), []))
        "(foo())()".makes(.callAnon(.call("foo", []), []))
        "foo()".makes(.call("foo", []))
        "foo(bar)".makes(.call("foo", [.variable("bar")]))
        "foo(bar())".makes(.call("foo", [.call("bar", [])]))
        "foo(bar(baz()))".makes(.call("foo", [.call("bar", [.call("baz", [])])]))
        "foo(bar()())".makes(.call("foo", [.callAnon(.call("bar", []), [])]))
        "foo(bar(baz()())())".makes(.call("foo", [.callAnon(.call("bar", [.callAnon(.call("baz", []), [])]), [])]))
        "foo(bar(baz()())()).inc".ok()
//        "foo(|x|x)".makes(.call("foo", [.]))
        "foo((|x|x))".ok()
        "foo(|x|x,|y|y)".ok()
        "foo(|x|x.foo(bar()())(),1)".ok()

        "1.foo()".ok() //          # .call(foo, 1)
        "1.foo(2)(3)".ok() //      # .anon(.call(foo, 1, 2), 3)
        "1.foo(2)(3).bar".ok() //  # .call(bar, .anon(.call(foo, 1, 2), 3))
        "1.(foo)(2)(3)".ok() //    # .anon(.anon(.var(foo), 1), 2)
        "(1.foo)(2)".ok() //       # .anon(.call(foo, 1), 2)
        "1.foo()(2)".ok() //       # .anon(.call(foo, 1), 2)
        "1.(foo())(2)".ok() //     # .anon(.anon(.call(foo), 1) ,2)
        "1.foo(3)(4)".ok() //      # .anon(.call(foo, 1, 3), 4)
        "1.(foo(3))(2)".ok() //    # .anon(.anon(.call(foo, 3), 1), 2)
        "foo.bar.baz".ok() //      # .call(baz, .call(bar, .var(foo)))
        "foo(1).foo(2)(3).bar".ok() // # .call(bar, .anon(.call(foo, .call(foo, 1), 2), 3))
        "(foo).bar".ok() //        # .call(bar, .var(foo))
        "(foo(2)).bar".ok() //    # .call(bar, .call(foo, 2))
        "1.(foo.bar).bar".ok() //  # .call(bar, .anon(.call(bar, .var(foo)), 1))
        "(foo.bar).bar".ok() //    # .call(bar, .call(bar, .var(foo)))
        "foo(bar())".ok() //       # .call(foo, .call(bar))
        "foo(4.bar)".ok() //       # .call(foo, .call(bar, 4))
        "foo(4.bar())".ok() //     # .call(foo, .call(bar, 4))
        "foo().bar".ok() //        # .call(bar, .call(foo))
        "foo()().bar".ok() //      # .call(bar, .anon(.call(foo)))
        "foo.bar()()".ok() //      # .anon(.call(bar, .var(foo)))
        "foo(4.foo(bar(2))).(foo()().bar).bar(3)".ok() //  # .call(bar, ... , 3)
        "(|x|x)(1)".ok() //        # .anon(|x|x, 1)
        "(|x|x).foo(1)".ok() //    # .call(foo, |x|x, 1)
        "(x)(1)(2,3).bar".ok() //  # .call(bar, .anon(.anon(x, 1), 2, 3))
        "(|x|x)(1)(2,3).bar".ok() //    # .call(bar, .anon(.anon(|x|x, 1), 2, 3))
        "(|x|x)().bar".ok() //     # .call(bar, .anon(|x|x))
        "1.(|x|x)".ok() //         # .anon(|x|x, 1)
        "1.(|x|x)()".ok() //       # .anon(.anon(|x|x, 1))
        "foo().(|x|x)()".ok() //   # .anon(.anon(|x|x, .call(foo)))
        "foo.bar(|x|x).baz".ok() //# .call(baz, .call(bar, .var(foo), |x|x))
        "bar(|x|x)".ok() //        # .call(bar, |x|x)
        "bar(|x|foo(x))".ok() //   # .call(bar, |x|foo(x))
        "bar((|x|x))".ok() //      # .call(bar, |x|x)
        "x.foo(2)(3,4)(5).bar(6)(7)".ok() //
        "x.foo(2)(3).bar".ok() //  # .call(bar, .call(foo, 1, 2))
        "1.foo".ok() //            # .call(foo, 1)
        "lessthan(5)(4)".ok() //   # .anon(.call(lessThan, 5), 4)
        "(foo)()".ok() //
        "(1+2).foo".ok() //

        "4()".fails()
        "4.|x|x".fails()
        "(4)()".fails()
    }
}
