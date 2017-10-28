public typealias Context = [String: Expression]

func contextDescription(context: Context) -> String {
    var contextPairs = Array<String>()
    for (key, value) in context {
        contextPairs.append("\(key) = \(value)")
    }
    return contextPairs.sorted().joined(separator: ", ")
}

func extendContext(context: Context, name: String, value: Expression) -> Context {
    var extendedContext = context
    extendedContext[name] = value
    return extendedContext
}

func extendContext(context: Context, parameters: [String], arguments: [Expression], callingContext: Context) -> Context {
    var extendedContext = context
    for i in 0..<parameters.count {
        let name = parameters[i]
        let value = arguments[i] 
        let evaluatedValue = value.evaluate(context: callingContext)
        extendedContext = extendContext(context: extendedContext, name: name, value: evaluatedValue)
    }
    return extendedContext
}