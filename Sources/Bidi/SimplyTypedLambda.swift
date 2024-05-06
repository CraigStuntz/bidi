public typealias Name = String

public enum Message: Error, CustomStringConvertible {
  case cannotType(Expr)
  /// Associated values are the name of the function, the expected type, and the actual type
  case incorrectType(Name, Type, Type)
  case lambdaRequiresArrow(Type)
  case notAFunction(Type)
  case notANat(Type)
  case notFound(Name)
  /// Associated values are the expected type and the actual type
  case unexpectedType(Type, Type)

  public var description: String {
    switch self {
    case .cannotType(let other):
      return "Can't find a type for \(String(describing: other)). Try adding a type annotation."
    case .incorrectType(let name, let expected, let other):
      return
        "\(name) should be a \(String(describing: expected)), but was used where a \(String(describing: other)) was expected"
    case .lambdaRequiresArrow(let other):
      return "Lambda requires a function type, but got \(String(describing: other))"
    case .notAFunction(let other): return "Not a function type: \(String(describing: other))"
    case .notANat(let other): return "Not the type Nat: \(String(describing: other))"
    case .notFound(let name): return "Not found: \(name)"
    case .unexpectedType(let expected, let other):
      return "Expected \(String(describing: expected)) but got \(String(describing: other))"
    }
  }
}

public indirect enum Expr {
  case variable(Name)
  /// Constructor of function type
  case lambda(Name, Expr)
  /// tarr eliminator
  case application(Expr, Expr)
  /// One constructor of tnat
  case zero
  /// Another constructor of tnat
  case add1(Expr)
  /// recursion is primitive recursion on Nat. The associated values are the type of the
  /// result, target, base, and step. If target is zero, then the whole
  /// expression is base. If target is (add1 n), then the whole expression is
  /// (step n (rec-Nat n base step)). Another tarr eliminator.
  case recursion(Type, Expr, Expr, Expr)
  case annotation(Expr, Type)
}

public indirect enum Type: Equatable {
  /// The type of natural numbers
  case tnat
  /// Arrow type (function), Associated values are arg and ret (the type of the
  /// argument to the function and the type the function returns)
  case tarr(Type, Type)
}

public struct Context {
  let values: [Name: Type]

  public init(values: [Name: Type]) {
    self.values = values
  }

  public init() {
    self.init(values: [:])
  }

  func extend(name: Name, type: Type) -> Context {
    var result = values
    result[name] = type
    return Context(values: result)
  }

  subscript(name: Name) -> Type? {
    return self.values[name]
  }

  public func lookup(name: Name) -> Result<Type, Message> {
    guard let type = self[name] else {
      return .failure(.notFound(name))
    }
    return .success(type)
  }

  public func synth(expr: Expr) -> Result<Type, Message> {
    switch expr {
    case .variable(let name): return lookup(name: name)
    case .application(let rator, let rand):
      return self.synth(expr: rator).flatMap {
        ty in
        switch ty {
        case .tarr(let argT, let retT):
          return check(expr: rand, type: argT).flatMap { () in .success(retT) }
        case .tnat: return .failure(.notAFunction(ty))
        }
      }
    case .recursion(let ty, let tgt, let base, let step):
      return self.synth(expr: tgt).flatMap { tgtT in
        switch tgtT {
        case .tnat:
          return check(expr: base, type: tgtT).flatMap {
            () in
            check(expr: step, type: .tarr(.tnat, .tarr(ty, ty))).flatMap {
              () in .success(ty)
            }
          }
        case .tarr: return .failure(.notANat(tgtT))
        }
      }
    case .annotation(let e, let t): return check(expr: e, type: t).flatMap { () in .success(t) }
    case .add1, .lambda, .zero: return .failure(.cannotType(expr))
    }
  }

  public func check(expr: Expr, type: Type) -> Result<Void, Message> {
    switch expr {
    case .lambda(let x, let body):
      switch type {
      case .tarr(let arg, let ret):
        return
          self
          .extend(name: x, type: arg)
          .check(expr: body, type: ret)
      case .tnat: return .failure(.lambdaRequiresArrow(type))
      }
    case .zero:
      switch type {
      case .tnat: return .success(())
      case .tarr: return .failure(.incorrectType("Zero", .tnat, type))
      }
    case .add1(let n):
      switch type {
      case .tnat: return self.check(expr: n, type: .tnat)
      case .tarr: return .failure(.incorrectType("Add1", .tnat, type))
      }
    default:
      return synth(expr: expr).flatMap { type2 in
        if type == type2 {
          return .success(())
        }
        return .failure(.unexpectedType(type, type2))
      }
    }
  }
}
