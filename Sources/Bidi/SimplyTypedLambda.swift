import Shared

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

  public func eval(_ env: Env) -> Value {
    switch self {
    case .variable(let name):
      guard let v = env[name] else {
        fatalError("Internal error: \(name) not found in environment")
      }
      return v
    case .lambda(let arg, let body):
      return .vclosure(env, arg, body)
    case .application(let rator, let rand):
      return rator.eval(env)
        .apply(arg: rand.eval(env))
    case .zero:
      return .vzero
    case .add1(let n):
      return .vadd1(n.eval(env))
    case .recursion(let t, let tgt, let base, let step):
      return tgt.eval(env).rec(t: t, base: base.eval(env), step: step.eval(env))
    case .annotation(let e, _):
      return e.eval(env)
    }
  }
}

public typealias Context = [Name: Type]
public typealias Defs = [(name: Name, expr: Expr)]
public typealias Env = [Name: Value]

public indirect enum Type: Equatable {
  /// The type of natural numbers
  case tnat
  /// Arrow type (function), Associated values are arg and ret (the type of the
  /// argument to the function and the type the function returns)
  case tarr(Type, Type)
}

extension Context {
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
          .extend(name: x, value: arg)
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

public indirect enum Value {
  case vzero
  case vadd1(Value)
  case vclosure(Env, Name, Expr)
  case vneutral(Type, Neutral)

  public func apply(arg: Value) -> Value {
    switch self {
    case .vclosure(let env, let x, let body):
      return body.eval(env.extend(name: x, value: arg))
    case .vneutral(let ty, let neu):
      guard case .tarr(let t1, let t2) = ty else {
        fatalError("Internal error; expected a .tarr here")
      }
      return .vneutral(t2, .napp(neu, Normal(normalType: t1, normalValue: arg)))
    case .vzero, .vadd1: fatalError("\(self) not exepcted here")
    }
  }

  public func rec(t: Type, base: Value, step: Value) -> Value {
    switch self {
    case .vzero: return base
    case .vadd1(let n):
      return step.apply(arg: n)
        .apply(arg: n.rec(t: t, base: base, step: step))
    case .vneutral(let typ, let neu):
      guard case .tnat = typ else {
        fatalError("Expected a .tnat here")
      }
      return .vneutral(
        t,
        .nrec(
          t, neu,
          Normal(normalType: t, normalValue: base),
          Normal(normalType: .tarr(.tnat, .tarr(t, t)), normalValue: step)))
    case .vclosure:
      fatalError("VClosure not expected here")
    }
  }
}

public indirect enum Neutral {
  case nvar(Name)
  case napp(Neutral, Normal)
  case nrec(Type, Neutral, Normal, Normal)
}

public struct Normal {
  let normalType: Type
  let normalValue: Value
}

public struct Program {
  let maybeEnv: Result<Context, Message>
  let body: Expr
  let used: [String]

  static func addDef(ctx: Context, name: Name, expr: Expr) -> Result<Context, Message> {
    return
      ctx.synth(expr: expr)
      .flatMap {
        (t: Type) in
        .success(ctx.extend(name: name, value: t))
      }
  }

  public static func addDefs(_ defs: Defs) -> Result<Context, Message> {
    return defs.reduce(
      .success(Context()),
      { (result, def) in
        result.flatMap { ctx in addDef(ctx: ctx, name: def.name, expr: def.expr) }
      }
    )
  }

  public init(defs: Defs, body: Expr) {
    self.body = body
    self.maybeEnv = Program.addDefs(defs)
    self.used = defs.map { def in def.name }
  }

  //   public func run() -> Result<Expr, Message> {
  //     maybeEnv.flatMap { ctx in
  //       body.eval(ctx: ctx)
  //         .flatMap { val in val.readBack(used: used) }
  //     }
  //   }
}
