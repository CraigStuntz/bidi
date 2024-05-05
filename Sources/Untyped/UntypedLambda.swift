import Foundation

public typealias Name = String

public enum Message: Error {
  case notFound(Name)
}

public protocol Show: CustomStringConvertible {
  func prettyPrint(offsetChars: Int) -> [String]
}

extension Show {
  public var description: String {
    let result = prettyPrint(offsetChars: indent)
    return String(result.joined(separator: "\n"))
  }
}

public protocol Value: Show {
  func apply(argValue: Value) -> Result<Value, Message>
  /// Think of readBack as "to Expr" (maybe!)
  func readBack(used: [String]) -> Result<Expr, Message>
}

public typealias Defs = [(name: Name, expr: Expr)]

let indent = 2

func padding(chars: Int) -> String {
  return "".padding(toLength: chars, withPad: " ", startingAt: 0)
}

let tab = padding(chars: indent)

public struct Env {
  let values: [Name: Value]

  subscript(name: Name) -> Value? {
    return self.values[name]
  }

  func extend(name: Name, value: Value) -> Env {
    var result = values
    result[name] = value
    return Env(values: result)
  }

  init(values: [Name: Value]) {
    self.values = values
  }

  public init() {
    self.init(values: [:])
  }

  func prettyPrint(offsetChars: Int) -> [String] {
    var result: [String] = []
    let leftPad = padding(chars: offsetChars)
    for key in values.keys.sorted() {
      result.append("\(leftPad)\(tab)(\(key)")
      if let value = values[key] {
        result.append(contentsOf: value.prettyPrint(offsetChars: offsetChars + indent + indent))
      }
      result.append("\(leftPad)\(tab))")
    }
    return result
  }
}

public struct VClosure: Value {
  let env: Env
  let variable: Name  // Christiansen calls this `var`, but `var` is a Swift keyword
  let body: Expr

  public func apply(argValue: Value) -> Result<Value, Message> {
    return body.eval(env: self.env.extend(name: variable, value: argValue))
  }

  public func prettyPrint(offsetChars: Int) -> [String] {
    var result: [String] = []
    let leftPad = padding(chars: offsetChars)
    result.append("\(leftPad)(VClosure")
    result.append("\(leftPad)\(tab)(env [")
    result.append(contentsOf: env.prettyPrint(offsetChars: offsetChars + indent))
    result.append("\(leftPad)\(tab)])")
    result.append("\(leftPad)\(tab)(variable \(variable))")
    result.append("\(leftPad)\(tab)(body")
    result.append(contentsOf: body.prettyPrint(offsetChars: offsetChars + indent + indent))
    result.append("\(leftPad)\(tab))")
    result.append("\(leftPad))")
    return result
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
    let x = freshen(used: used, x: variable)
    var newUsed = used
    newUsed.append(x)
    return self.apply(argValue: VNeutral(neutral: .nvar(x)))
      .flatMap { bodyVal in
        bodyVal.readBack(used: newUsed)
          .flatMap { bodyExpr in .success(.lambda(x, bodyExpr)) }
      }
  }
}

public indirect enum Neutral {
  case nvar(Name)
  case napp(Neutral, Value)

  func prettyPrint(offsetChars: Int) -> [String] {
    var result: [String] = []
    let leftPad = padding(chars: offsetChars)
    switch self {
    case .nvar(let name):
      result.append("\(leftPad)(NVar \(name))")
    case .napp(let neutral, let value):
      result.append("\(leftPad)(NApp")
      result.append(contentsOf: neutral.prettyPrint(offsetChars: offsetChars + indent))
      result.append(contentsOf: value.prettyPrint(offsetChars: offsetChars + indent))
      result.append("\(leftPad))")
    }
    return result
  }
}

public struct VNeutral: Value {
  let neutral: Neutral

  public func apply(argValue: Value) -> Result<Value, Message> {
    return .success(VNeutral(neutral: .napp(neutral, argValue)))
  }

  public init(neutral: Neutral) {
    self.neutral = neutral
  }

  public func prettyPrint(offsetChars: Int) -> [String] {
    var result: [String] = []
    let leftPad = padding(chars: offsetChars)
    result.append("\(leftPad)(VNeutral")
    result.append(contentsOf: neutral.prettyPrint(offsetChars: offsetChars + indent))
    result.append("\(leftPad))")
    return result
  }

  public func readBack(used: [String]) -> Result<Expr, Message> {
    switch neutral {
    case .nvar(let name):
      return .success(.variable(name))
    case .napp(let fun, let arg):
      return VNeutral(neutral: fun)
        .readBack(used: used)
        .flatMap { rator in
          arg.readBack(used: used)
            .flatMap { rand in .success(.application(rator, rand)) }
        }
    }
  }
}

public indirect enum Expr: Show {
  case variable(Name)
  case lambda(Name, Expr)
  case application(Expr, Expr)

  /// Think of eval as "to Value" (maybe!)
  public func eval(env: Env) -> Result<Value, Message> {
    switch self {
    case .variable(let name):
      guard let value = env[name] else {
        return .failure(.notFound(name))
      }
      return .success(value)
    case .lambda(let name, let body):
      return .success(VClosure(env: env, variable: name, body: body))
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
    return self.eval(env: Env(values: [:]))
      .flatMap { val in val.readBack(used: []) }
  }

  public func prettyPrint(offsetChars: Int) -> [String] {
    var result: [String] = []
    let leftPad = padding(chars: offsetChars)
    switch self {
    case .variable(let name):
      result.append("\(leftPad)(Var \(name))")
    case .lambda(let name, let body):
      result.append("\(leftPad)(Lambda \(name)")
      result.append(contentsOf: body.prettyPrint(offsetChars: offsetChars + indent))
      result.append("\(leftPad))")
    case .application(let rator, let rand):
      result.append("\(leftPad)(App")
      result.append(contentsOf: rator.prettyPrint(offsetChars: offsetChars + indent))
      result.append(contentsOf: rand.prettyPrint(offsetChars: offsetChars + indent))
      result.append("\(leftPad))")
    }
    return result
  }
}

public struct Program {
  let maybeEnv: Result<Env, Message>
  let body: Expr
  let used: [String]

  static func addDef(env: Env, name: Name, expr: Expr) -> Result<Env, Message> {
    return
      expr
      .eval(env: env)
      .flatMap {
        (v: Value) in
        .success(env.extend(name: name, value: v))
      }
  }

  static func addDefs(_ defs: Defs) -> Result<Env, Message> {
    return defs.reduce(
      .success(Env()),
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
