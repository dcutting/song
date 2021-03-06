import Foundation
import Syft

public func makeParser() -> ParserProtocol {

    // Punctuation.

    let newline = str("\n")
    let space = " \t".match.some
    let spaceOrNewline = space | newline
    let skip = space.maybe
    let skipSpaceAndNewlines = spaceOrNewline.some.maybe
    let dot = str(".")
    let pipe = str("|") >>> skip
    let comma = str(",")
    let delimiter = str(",")
    let lBracket = str("[")
    let rBracket = str("]")
    let lParen = str("(") >>> skip
    let rParen = str(")")
    let singleQuote = str("'")
    let doubleQuote = str("\"")
    let backslash = str("\\")
    let underscore = str("_")
    let questionMark = str("?")
    let digit = (0...9).match
    let lowercaseLetter = "abcdefghijklmnopqrstuvwxyz".match
    let uppercaseLetter = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".match
    let letter = lowercaseLetter | uppercaseLetter

    let textAlphanumeric = Parser.char(.alphanumerics)
    let textQuoteChars = CharacterSet(charactersIn: "'\"")
    let textBackslashChars = CharacterSet(charactersIn: "\\")
    let textPunctuation = Parser.char(CharacterSet.punctuationCharacters.subtracting(textQuoteChars).subtracting(textBackslashChars))
    let textSymbol = Parser.char(CharacterSet.symbols.subtracting(textQuoteChars))
    let textWhitespace = Parser.char(.whitespacesAndNewlines)
    let textCharacter = textAlphanumeric | textWhitespace | textSymbol | textPunctuation
    let textEscapedControl = backslash >>> (backslash | "nrt".match)
    let textEscapedSingleQuote = backslash >>> singleQuote
    let textEscapedDoubleQuote = backslash >>> doubleQuote
    let textLiteralChar = textEscapedControl | textCharacter
    let textLiteralCharInChar = textEscapedSingleQuote | doubleQuote | textLiteralChar
    let textLiteralCharInString = textEscapedDoubleQuote | singleQuote | textLiteralChar

    let star = str("*")
    let slash = str("/")
    let div = str("Div")
    let mod = str("Mod")
    let plus = str("+")
    let minus = str("-")
    let lessThanOrEqual = str("<=")
    let greaterThanOrEqual = str(">=")
    let lessThan = str("<")
    let greaterThan = str(">")
    let equalTo = str("Eq")
    let notEqualTo = str("Neq")
    let logicalAnd = str("And")
    let logicalOr = str("Or")
    let logicalNot = str("Not")
    let yes = str("Yes")
    let no = str("No")
    let when = spaceOrNewline >>> str("When") >>> spaceOrNewline
    let assign = str("=")
    let start = str("Do")
    let end = str("End")

    let expression = Deferred()
    let wrappedExpression = lParen >>> expression.tag("wrapped") >>> rParen

    let scope = Deferred()

    // Lists.

    let listItem = skip >>> (expression.tag("item") | newline) >>> skip
    let listItemDelimiter = skipSpaceAndNewlines >>> comma >>> skipSpaceAndNewlines
    let listItems = listItem >>> (listItemDelimiter >>> listItem).recur
    let list = lBracket >>> skipSpaceAndNewlines >>> listItems.recur.tag("list") >>> skipSpaceAndNewlines >>> rBracket

    let heads = listItems.tag("heads")
    let tail = expression.tag("tail")
    let listConstructor = lBracket >>> skipSpaceAndNewlines >>> heads >>> skipSpaceAndNewlines >>> pipe >>> skipSpaceAndNewlines >>> tail >>> skipSpaceAndNewlines >>> rBracket

    // Literals.

    let trueValue = yes.tag("true")
    let falseValue = no.tag("false")
    let booleanValue = trueValue | falseValue
    let integerValue = digit.some.tag("integer")
    let floatValue = (digit.some >>> dot >>> digit.some).tag("float")
    let numericValue = floatValue | integerValue
    let characterValue = singleQuote >>> textLiteralCharInChar.tag("character") >>> singleQuote
    let stringValue = doubleQuote >>> textLiteralCharInString.some.maybe.tag("string") >>> doubleQuote

    let literalValue = stringValue | characterValue | list | listConstructor | numericValue | booleanValue

    // Names.

    let namePrefix = underscore | lowercaseLetter
    let nameSuffix = letter | digit | underscore | questionMark
    let name = namePrefix >>> nameSuffix.some.maybe
    let variableName = name.tag("variableName")
    let functionName = name.tag("functionName")

    let parameter = (literalValue | variableName).tag("param")
    let parameterDelimiter = skipSpaceAndNewlines >>> comma >>> skipSpaceAndNewlines
    let parameters = parameter >>> (parameterDelimiter >>> parameter).recur

    // Lambdas.

    let lambdaParameter = (list | listConstructor | variableName).tag("param")
    let lambdaParameters = lambdaParameter >>> (parameterDelimiter >>> lambdaParameter).recur

    let lambda = (pipe >>> skipSpaceAndNewlines >>> lambdaParameters.recur(0, 1).tag("params") >>> skipSpaceAndNewlines >>> pipe >>> skipSpaceAndNewlines >>> (wrappedExpression | expression).tag("body")).tag("lambda")

    // Function calls.

    let call = Deferred()

    let argument = Deferred()
    let wrappedArgument = lParen >>> argument >>> rParen
    argument.parser = wrappedArgument | expression
    let argumentDelimiter = skipSpaceAndNewlines >>> comma >>> skipSpaceAndNewlines
    let arguments = argument >>> (argumentDelimiter >>> argument).recur
    let wrappedArguments = lParen >>> skipSpaceAndNewlines >>> arguments.recur.tag("args") >>> skipSpaceAndNewlines >>> rParen

    let callable = Deferred()
    let wrappedCallable = lParen >>> callable >>> rParen
    callable.parser = wrappedCallable | call | variableName | lambda | scope

    let groupName = name.tag("functionName")
    let groupAnon = lParen >>> callable >>> rParen
    let groupAnonCall = groupAnon.tag("anonCall") >>> wrappedArguments.maybe
    let groupAnonCallWithArgs = groupAnon.tag("anonCall") >>> wrappedArguments
    let groupNameCall = groupName >>> wrappedArguments
    let trailCalls = (lParen >>> arguments.recur.tag("args") >>> rParen).tag("anonCall").recur
    let dotGroupCall = groupNameCall.tag("nameCall") | groupAnonCall
    let headGroupCall = groupNameCall.tag("nameCall") | groupAnonCallWithArgs
    let group = dotGroupCall | groupName.tag("nameCall") | wrappedExpression
    let dotHead = (headGroupCall >>> trailCalls).tag("trailCalls") | wrappedExpression | variableName | literalValue
    let dotGroup = dot >>> group
    let dotCall = dotHead.tag("head") >>> dotGroup >>> trailCalls >>> (dotGroup >>> trailCalls).recur

    let freeCall = (dotGroupCall >>> trailCalls).tag("trailCalls")

    call.parser = dotCall.tag("dotCall") | freeCall

    // Function declarations.

    let functionSubject = parameter.tag("subject")
    let functionParameters = skipSpaceAndNewlines >>> lParen >>> skipSpaceAndNewlines >>> parameters.recur(0, 1).tag("params") >>> skipSpaceAndNewlines >>> rParen
    let functionBody = skip >>> expression.tag("body") >>> skip
    let guardClause = (when >>> expression).maybe.tag("guard") >>> skip
    let subjectFunctionDecl = functionSubject >>> dot >>> functionName >>> functionParameters.maybe >>> guardClause >>> assign >>> skipSpaceAndNewlines >>> functionBody

    let freeFunctionDecl = functionName >>> functionParameters >>> guardClause >>> assign >>> skipSpaceAndNewlines >>> functionBody

    let functionDecl = subjectFunctionDecl | freeFunctionDecl

    // Expressions.

    let relational = Deferred()
    let equality = Deferred()
    let conjunctive = Deferred()
    let disjunctive = Deferred()
    let term = Deferred()

    let symbolicMultiplicativeOp = skipSpaceAndNewlines >>> (star | slash).tag("op") >>> skipSpaceAndNewlines
    let wordMultiplicativeOp = spaceOrNewline >>> (mod | div).tag("op") >>> spaceOrNewline
    let multiplicativeOp = symbolicMultiplicativeOp | wordMultiplicativeOp
    let multiplicative = term.tag("left") >>> (multiplicativeOp >>> term.tag("right")).recur.tag("ops")
    let additive = multiplicative.tag("left") >>> (skipSpaceAndNewlines >>> (plus | minus).tag("op") >>> skipSpaceAndNewlines >>> multiplicative.tag("right")).recur.tag("ops")
    relational.parser = additive.tag("left") >>> (skipSpaceAndNewlines >>> (lessThanOrEqual | greaterThanOrEqual | lessThan | greaterThan).tag("op") >>> skipSpaceAndNewlines >>> relational.tag("right")).recur.tag("ops")
    equality.parser = relational.tag("left") >>> (spaceOrNewline >>> (equalTo | notEqualTo).tag("op") >>> spaceOrNewline >>> equality.tag("right")).recur.tag("ops")
    conjunctive.parser = equality.tag("left") >>> (spaceOrNewline >>> logicalAnd.tag("op") >>> spaceOrNewline >>> conjunctive.tag("right")).recur.tag("ops")
    disjunctive.parser = conjunctive.tag("left") >>> (spaceOrNewline >>> logicalOr.tag("op") >>> spaceOrNewline >>> disjunctive.tag("right")).recur.tag("ops")

    expression.parser = disjunctive.parser

    // Terms.

    let negateOp = (logicalNot.tag("op") >>> spaceOrNewline) | minus.tag("op")
    let negateTerm = negateOp >>> term.tag("right")
    let plusTerm = plus >>> term
    term.parser = negateTerm | plusTerm | scope | call | lambda | variableName | literalValue | wrappedExpression

    // Constants.

    let constant = variableName.tag("variable") >>> skipSpaceAndNewlines >>> assign >>> skipSpaceAndNewlines >>> expression.tag("constBody")

    // Scopes.

    let statement = Deferred()
    let scopeItem = skip >>> statement.tag("scopeStatement")
    let delimiterOrNewline = skip >>> ((delimiter.maybe >>> skip >>> newline) | delimiter)
    let scopeItems = (scopeItem >>> (delimiterOrNewline >>> scopeItem).recur).tag("scopeItems") >>> delimiter.maybe
    scope.parser = start >>> spaceOrNewline >>> skipSpaceAndNewlines >>> scopeItems >>> spaceOrNewline >>> skipSpaceAndNewlines >>> end
    let declaration = functionDecl | constant
    statement.parser = skipSpaceAndNewlines >>> (declaration | expression)

    // Root.

    let root = statement >>> skipSpaceAndNewlines

    return root
}
