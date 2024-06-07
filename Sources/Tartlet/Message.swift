import Shared

public indirect enum Message: Error, CustomStringConvertible {
  case alreadyDefined(Name)
  case cannotSynthesize(Expr)
  case incorrectType(Name)
  case notSameType(Expr, Expr)
  case unboundVariable(Name)
  case unexpected(Message, Expr)

  public var description: String {
    switch self {
    case .alreadyDefined(let name): "The name \(name) is already defined."
    case .cannotSynthesize(let expr): "Unable to synthesize a type for \(expr)"
    case .incorrectType(let name): "Not a \(name) type"
    case .notSameType(let expr1, let expr2): "\(expr1) is not the same type as \(expr2)"
    case .unboundVariable(let name): "Unbound variable: \(name)"
    case .unexpected(let message, let expr): "\(message): \(expr)"
    }
  }
}
