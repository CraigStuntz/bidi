import Foundation
import Shared

public enum Message: Error {
  case notFound(Name)
}

public typealias Defs = [(name: Name, expr: Expr)]

public indirect enum Neutral {
  case nvar(Name)
  case napp(Neutral, Value)
}

public enum Value {
  /// The associated values here are the environment, the variable (function argument) name, and the body
  case vclosure(Env<Value>, Name, Expr)
  case vneutral(Neutral)

  public func apply(argValue: Value) -> Result<Value, Message> {
    switch self {
    case .vclosure(let env, let variable, let body):
      return body.eval(env: env.extend(name: variable, value: argValue))
    case .vneutral(let neutral):
      return .success(.vneutral(.napp(neutral, argValue)))
    }
  }

  private func nextName(x: Name) -> Name {
    return x + "'"
  }

  private func freshen(used: [Name], x: Name) -> Name {
    if used.contains(x) {
      return freshen(used: used, x: nextName(x: x))
    }
    return x
  }

  public func readBack(used: [String]) -> Result<Expr, Message> {
    switch self {
    case .vclosure(_, let variable, _):
      let x = freshen(used: used, x: variable)
      var newUsed = used
      newUsed.append(x)
      return self.apply(argValue: .vneutral(.nvar(x)))
        .flatMap { bodyVal in
          bodyVal.readBack(used: newUsed)
            .flatMap { bodyExpr in .success(.lambda(x, bodyExpr)) }
        }
    case .vneutral(let neutral):
      switch neutral {
      case .nvar(let name):
        return .success(.variable(name))
      case .napp(let fun, let arg):
        return Value.vneutral(fun)
          .readBack(used: used)
          .flatMap { rator in
            arg.readBack(used: used)
              .flatMap { rand in .success(.application(rator, rand)) }
          }
      }
    }
  }
}

public indirect enum Expr {
  case variable(Name)
  case lambda(Name, Expr)
  case application(Expr, Expr)

  /// Think of eval as "to Value" (maybe!)
  public func eval(env: Env<Value>) -> Result<Value, Message> {
    switch self {
    case .variable(let name):
      guard let value = env[name] else {
        return .failure(.notFound(name))
      }
      return .success(value)
    case .lambda(let name, let body):
      return .success(.vclosure(env, name, body))
    // "The names rator and rand are short for 'operator' and 'operand.'
    //  These names go back to Landin (1964)."
    case .application(let rator, let rand):
      return rator.eval(env: env)
        .flatMap {
          (fun: Value) in
          rand.eval(env: env)
            .flatMap {
              (arg: Value) in fun.apply(argValue: arg)
            }
        }
    }
  }

  // Unused in David's document?
  public func normalize() -> Result<Expr, Message> {
    return self.eval(env: Env<Value>())
      .flatMap { val in val.readBack(used: []) }
  }
}

public struct Program {
  let maybeEnv: Result<Env<Value>, Message>
  let body: Expr
  let used: [String]

  static func addDef(env: Env<Value>, name: Name, expr: Expr) -> Result<Env<Value>, Message> {
    return
      expr
      .eval(env: env)
      .flatMap {
        (v: Value) in
        .success(env.extend(name: name, value: v))
      }
  }

  static func addDefs(_ defs: Defs) -> Result<Env<Value>, Message> {
    return defs.reduce(
      .success(Env<Value>()),
      { (result, def) in
        result.flatMap { env in addDef(env: env, name: def.name, expr: def.expr) }
      }
    )
  }

  public init(defs: Defs, body: Expr) {
    self.body = body
    self.maybeEnv = Program.addDefs(defs)
    self.used = defs.map { def in def.name }
  }

  public func run() -> Result<Expr, Message> {
    maybeEnv.flatMap { env in
      body.eval(env: env)
        .flatMap { val in val.readBack(used: used) }
    }
  }
}
