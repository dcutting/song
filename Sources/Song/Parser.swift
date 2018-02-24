import Syft

public func makeParser() -> ParserProtocol {

    // Punctuation.

    let space = " \t".match.some
    let skip = space.maybe
    let dot = str(".")
    let pipe = str("|") >>> skip
    let comma = skip >>> str(",") >>> skip
    let lBracket = str("[") >>> skip
    let rBracket = str("]") >>> skip
    let lParen = str("(") >>> skip
    let rParen = str(")")
    let quote = str("\"")
    let backslash = str("\\")
    let underscore = str("_")
    let digit = (0...9).match
    let lowercaseLetter = "abcdefghijklmnopqrstuvwxyz".match
    let uppercaseLetter = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".match
    let letter = lowercaseLetter | uppercaseLetter
    let symbol = dot | pipe | comma | lBracket | rBracket | lParen | rParen | underscore | "!@#$%^&*-=_+`~,.<>/?':;\\|[]{}".match
    let stringChar = Deferred()
    stringChar.parser = backslash >>> (backslash | quote) | letter | digit | space | symbol
    let star = str("*")
    let slash = str("/")
    let div = str("div")
    let mod = str("mod")
    let plus = str("+")
    let minus = str("-")
    let lessThanOrEqual = str("<=")
    let greaterThanOrEqual = str(">=")
    let lessThan = str("<")
    let greaterThan = str(">")
    let equalTo = str("eq")
    let notEqualTo = str("neq")
    let logicalAnd = str("and")
    let logicalOr = str("or")
    let logicalNot = str("not")
    let when = space >>> str("when") >>> space
    let assign = str("=") >>> skip

    let expression = Deferred()
    let scope = Deferred()

    // Lists.

    let item = expression.tag("item")
    let list = lBracket >>> (item >>> (comma >>> item).recur).recur.tag("list") >>> rBracket

    let heads = (skip >>> item >>> (comma >>> item >>> skip).recur).tag("heads")
    let tail = expression.tag("tail")
    let listConstructor = lBracket >>> heads >>> skip >>> pipe >>> skip >>> tail >>> skip >>> rBracket

    // Literals.

    let trueValue = str("yes").tag("true")
    let falseValue = str("no").tag("false")
    let booleanValue = trueValue | falseValue
    let integerValue = (minus.maybe >>> digit.some).tag("integer")
    let floatValue = (minus.maybe >>> digit.some >>> dot >>> digit.some).tag("float")
    let numericValue = floatValue | integerValue
    let stringValue = quote >>> stringChar.recur.tag("string") >>> quote >>> skip

    let literalValue = booleanValue | numericValue | stringValue | list | listConstructor

    // Names.

    let namePrefix = underscore | lowercaseLetter
    let nameSuffix = letter | digit | underscore
    let name = namePrefix >>> nameSuffix.some.maybe
    let variableName = name.tag("variableName")
    let functionName = name.tag("functionName")

    // Function calls.

    let wrappedExpression = lParen >>> expression.tag("wrapped") >>> rParen
    let arg = expression.tag("arg")
    let args = (arg >>> (comma >>> arg).recur).tag("args")
    let freeFunctionCall = functionName >>> (lParen >>> args.maybe >>> skip >>> rParen)
    let atom = wrappedExpression | freeFunctionCall | literalValue | variableName
    let subjectFunctionCall = atom.tag("subject") >>> (dot >>> functionName >>> (lParen >>> args.maybe >>> rParen).maybe).some.tag("calls")
    let functionCall = subjectFunctionCall | freeFunctionCall

    // Function declarations.

    let parameter = (literalValue | variableName).tag("param")
    let functionSubject = parameter.tag("subject")
    let parameters = parameter >>> (comma >>> parameter).recur
    let functionParameters = lParen >>> parameters.recur(0, 1).tag("params") >>> rParen
    let functionBody = (scope | expression).tag("body") >>> skip
    let guardClause = (when >>> expression).maybe.tag("guard") >>> skip
    let subjectFunctionDecl = functionSubject >>> dot >>> functionName >>> functionParameters.maybe >>> guardClause >>> assign >>> functionBody

    let freeFunctionDecl = functionName >>> functionParameters >>> guardClause >>> assign >>> functionBody

    let functionDecl = subjectFunctionDecl | freeFunctionDecl

    // Expressions.

    let relational = Deferred()
    let equality = Deferred()
    let conjunctive = Deferred()
    let disjunctive = Deferred()
    let term = Deferred()

    let symbolicMultiplicativeOp = skip >>> (star | slash).tag("op") >>> skip
    let wordMultiplicativeOp = space >>> (mod | div).tag("op") >>> space
    let multiplicativeOp = symbolicMultiplicativeOp | wordMultiplicativeOp
    let multiplicative = term.tag("left") >>> (multiplicativeOp >>> term.tag("right")).recur.tag("ops")
    let additive = multiplicative.tag("left") >>> (skip >>> (plus | minus).tag("op") >>> skip >>> multiplicative.tag("right")).recur.tag("ops")
    relational.parser = additive.tag("left") >>> (skip >>> (lessThanOrEqual | greaterThanOrEqual | lessThan | greaterThan).tag("op") >>> skip >>> relational.tag("right")).recur.tag("ops")
    equality.parser = relational.tag("left") >>> (space >>> (equalTo | notEqualTo).tag("op") >>> space >>> equality.tag("right")).recur.tag("ops")
    conjunctive.parser = equality.tag("left") >>> (space >>> logicalAnd.tag("op") >>> space >>> conjunctive.tag("right")).recur.tag("ops")
    disjunctive.parser = conjunctive.tag("left") >>> (space >>> logicalOr.tag("op") >>> space >>> disjunctive.tag("right")).recur.tag("ops")

    expression.parser = disjunctive.parser

    // Lambdas.

    let lambdaParameters = pipe >>> parameters.recur(0, 1).tag("params") >>> pipe
    let lambdaBody = expression.tag("lambdaBody") >>> skip
    let lambda = lambdaParameters >>> lambdaBody

    // Terms.

    let negatedTerm = logicalNot.tag("op") >>> space >>> term.tag("right")
    term.parser = negatedTerm | functionCall | lambda | atom

    // Constants.

    let constant = variableName.tag("variable") >>> skip >>> assign >>> (scope | expression).tag("constBody")

    // Scopes.

    let statement = Deferred()
    let scopeItem = statement.tag("arg")
    let scopeItems = (scopeItem >>> (comma >>> scopeItem).recur).tag("scopeItems")
    scope.parser = str("do") >>> space >>> scopeItems >>> skip >>> str("end")
    statement.parser = scope | functionDecl | constant | expression

    // Root.

    let root = statement

    return root
}
