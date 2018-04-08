public class Type { // TODO: this shouldn't be a class.
    public let name: String
    public var parent: Type?
    public let associated: [Type]

    public init(name: String, parent: Type?, associated: [Type]) {
        self.name = name
        self.parent = parent
        self.associated = associated
    }

    public static let Root = Type(name: "Root", parent: nil, associated: [])
    public static let Bool = Type(name: "Bool", parent: Root, associated: [])
    public static let Char = Type(name: "Char", parent: Root, associated: [])
    public static let Number = Type(name: "Number", parent: Root, associated: [])
    public static let Int = Type(name: "Int", parent: Number, associated: [])
    public static let Float = Type(name: "Float", parent: Number, associated: [])
    public static func ListOf(_ type: Type) -> Type {
        return Type(name: "List", parent: Root, associated: [type])
    }
    public static func Func(_ name: String, _ types: [Type]) -> Type {
        return Type(name: name, parent: Root, associated: types)
    }
}

extension Type: CustomStringConvertible {
    public var description: String {
        if associated.isEmpty {
            return name
        }
        let associatedNames = associated.map { $0.name }
        let joinedAssociatedNames = associatedNames.joined(separator: ", ")
        return "\(name)(\(joinedAssociatedNames))"
    }
}

public enum TypeCheckerError {
    case invalid(Expression)
    case unknownName(Expression)
    case notAClosure(Expression)
    case notAFunction(Expression)
    case arityMismatch(Expression)
    case typeMismatch(Expression, Type, Type)
}

public enum TypeCheckerResult {
    case valid(Type)
    case error(TypeCheckerError)
}

public class TypeChecker {

    private var types = [String: Type]()

    public init() {}

    public func storeType(for expression: Expression) {
        switch expression {
        case let .assign(variable, value):
            if case .name(let name) = variable {
                types[name] = type(value)
            }
        case let .function(f):
            guard let name = f.name else { return }
            let paramTypes = f.patterns.map { type($0) }
            let returnType = type(f.body)
            types[name] = .Func("Func", paramTypes + [returnType])
        default:
            ()
        }
    }

    public func verify(expression: Expression) -> TypeCheckerResult {
        switch expression {
        case .bool, .number, .char, .name:
            return .valid(type(expression))
        case let .call(name, args):
            guard let fType = types[name] else { return .error(.unknownName(expression))}
            guard args.count == fType.associated.count - 1 else { return .error(.arityMismatch(expression)) }
            print("expression.type: \(type(expression))")
            print("f.type: \(fType)")
            for (a, p) in zip(args, fType.associated) {
                let aType = type(a)
                let pName = p.name
                print("comparing: \(a, p)")
                guard pName == aType.name else { return .error(.typeMismatch(a, aType, p)) }
            }
            return .valid(type(expression))
        default:
            return .error(.invalid(expression))
        }
    }

    private func type(_ expr: Expression) -> Type {
        
        switch expr {
        case .bool:
            return .Bool
        case let .number(value):
            switch value {
            case .int:
                return .Int
            case .float:
                return .Float
            }
        case .char:
            return .Char
        case let .name(name):
            return types[name] ?? .Root

        case let .call(_, args):
            let argTypes = args.map { type($0) }
            return .Func("Call", argTypes)
        default:
            return .Root
        }
    }
}
