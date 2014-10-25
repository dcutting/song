//  Copyright (c) 2014 Yellowbek. All rights reserved.

import Foundation

public typealias SongContext = [String: SongExpression]

func contextDescription(context: SongContext) -> String {
    var contextPairs = Array<String>()
    for (key, value) in context {
        contextPairs.append("\(key) = \(value)")
    }
    contextPairs.sort { $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending }
    return ", ".join(contextPairs)
}

func extendContext(context: SongContext, #name: String, #value: SongExpression) -> SongContext {
    var extendedContext = context
    extendedContext[name] = value
    return extendedContext
}

func extendContext(context: SongContext, #parameters: [String], #arguments: [SongExpressionLike]) -> SongContext {
    var extendedContext = context
    for (var i = 0; i < parameters.count; i++) {
        var name = parameters[i]
        var value = arguments[i] as SongExpression
        extendedContext = extendContext(extendedContext, name: name, value: value)
    }
    return extendedContext
}
