public typealias Name = String

public enum Message: Error, CustomStringConvertible {
  case cannotType(Expr)
  case notAFunction(Type)
  case notANat(Type)
  case notFound(Name)

  public var description: String {
    switch self {
    case .cannotType(let other):
      return "Cannot find a type for \(String(describing: other)). Try adding a type annotation."
    case .notAFunction(let other): return "Not a function type: \(String(describing: other))"
    case .notANat(let other): return "Not the type Nat: \(String(describing: other))"
    case .notFound(let name): return "Not found: \(name)"
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
  /// Another tarr eliminator
  case recursion(Type, Expr, Expr, Expr)
  case annotation(Expr, Type)
}

public indirect enum Type {
  /// The type of natural numbers
  case tnat
  /// Arrow type (function)
  case tarr(Type, Type)
}

public struct Context {
  let values: [Name: Type]

  public init() {
    self.values = [:]
  }

  public func lookup(name: Name) -> Result<Type, Message> {
    guard let type = values[name] else {
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
          return check(expr: rand, ty: argT).flatMap { () in .success(retT) }
        default: return .failure(.notAFunction(ty))
        }
      }
    case .recursion(let ty, let tgt, let base, let step):
      return self.synth(expr: tgt).flatMap { tgtT in
        switch tgtT {
        case .tnat:
          return check(expr: base, ty: tgtT).flatMap {
            () in
            check(expr: step, ty: .tarr(.tnat, .tarr(ty, ty))).flatMap {
              () in .success(ty)
            }
          }
        default: return .failure(.notANat(tgtT))
        }
      }
    case .annotation(let e, let t): return check(expr: e, ty: t).flatMap { () in .success(t) }
    default: return .failure(.cannotType(expr))
    }
  }

  public func check(expr: Expr, ty: Type) -> Result<Void, Message> {
    return .failure(.cannotType(expr))
  }
}
