import Foundation

typealias Name = String

enum Message: Error {
  case notFound(Name)
}

protocol Value: CustomStringConvertible {
  func apply(argValue: Value) -> Result<Value, Message>
  func prettyPrint(offsetChars: Int) -> [String]
}

typealias Defs = [(name: Name, expr: Expr)]

let indent = 2

func padding(chars: Int) -> String {
  return "".padding(toLength: chars, withPad: " ", startingAt: 0)
}

let tab = padding(chars: indent)

struct Env {
  let values: [Name: Value]

  subscript(name: Name) -> Value? {
    return self.values[name]
  }

  func extend(name: Name, value: Value) -> Env {
    var result = values
    result[name] = value
    return Env(values: result)
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

struct VClosure: Value {
  let env: Env
  let argName: Name
  let body: Expr

  func apply(argValue: Value) -> Result<Value, Message> {
    return body.eval(env: self.env.extend(name: argName, value: argValue))
  }

  func prettyPrint(offsetChars: Int) -> [String] {
    var result: [String] = []
    let leftPad = padding(chars: offsetChars)
    result.append("\(leftPad)(VClosure")
    result.append("\(leftPad)\(tab)(env [")
    result.append(contentsOf: env.prettyPrint(offsetChars: offsetChars + indent))
    result.append("\(leftPad)\(tab)])")
    result.append("\(leftPad)\(tab)(argName \(argName))")
    result.append("\(leftPad)\(tab)(body")
    result.append(contentsOf: body.prettyPrint(offsetChars: offsetChars + indent + indent))
    result.append("\(leftPad)\(tab))")
    result.append("\(leftPad))")
    return result
  }

  var description: String {
    let result = prettyPrint(offsetChars: indent)
    return String(result.joined(separator: "\n"))
  }
}

indirect enum Neutral {
  case nvar(Name)
  case napp(Neutral, Value)

  func prettyPrint(offsetChars: Int) -> [String] {
    var result: [String] = []
    let leftPad = padding(chars: offsetChars)
    switch self {
    case .nvar(let name):
      result.append("\(leftPad)(NVar \(name))")
      break
    case .napp(let neutral, let value):
      result.append("\(leftPad)(NApp")
      result.append(contentsOf: neutral.prettyPrint(offsetChars: offsetChars + indent))
      result.append(contentsOf: value.prettyPrint(offsetChars: offsetChars + indent))
      result.append("\(leftPad))")
      break
    }
    return result
  }
}

struct VNeutral: Value {
  let neutral: Neutral

  func apply(argValue: Value) -> Result<Value, Message> {
    return .success(VNeutral(neutral: .napp(neutral, argValue)))
  }

  func prettyPrint(offsetChars: Int) -> [String] {
    var result: [String] = []
    let leftPad = padding(chars: offsetChars)
    result.append("\(leftPad)(VNeutral")
    result.append(contentsOf: neutral.prettyPrint(offsetChars: offsetChars + indent))
    result.append("\(leftPad))")
    return result
  }

  var description: String {
    let result = prettyPrint(offsetChars: indent)
    return String(result.joined(separator: "\n"))
  }
}

indirect enum Expr {
  case variable(Name)
  case lambda(Name, Expr)
  case application(Expr, Expr)

  func eval(env: Env) -> Result<Value, Message> {
    switch self {
    case .variable(let name):
      guard let value = env[name] else {
        return .failure(.notFound(name))
      }
      return .success(value)
    case .lambda(let name, let body):
      return .success(VClosure(env: env, argName: name, body: body))
    // "The names rator and rand are short for 'operator' and 'operand.'
    //  These names go back to Landin (1964).""
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

  func prettyPrint(offsetChars: Int) -> [String] {
    var result: [String] = []
    let leftPad = padding(chars: offsetChars)
    switch self {
    case .variable(let name):
      result.append("\(leftPad)(Var \(name))")
      break
    case .lambda(let name, let body):
      result.append("\(leftPad)(Lambda \(name)")
      result.append(contentsOf: body.prettyPrint(offsetChars: offsetChars + indent))
      result.append("\(leftPad))")
      break
    case .application(let rator, let rand):
      result.append("\(leftPad)(App")
      result.append(contentsOf: rator.prettyPrint(offsetChars: offsetChars + indent))
      result.append(contentsOf: rand.prettyPrint(offsetChars: offsetChars + indent))
      result.append("\(leftPad))")
      break
    }
    return result
  }
}

func addDef(env: Env, name: Name, expr: Expr) -> Result<Env, Message> {
  return
    expr
    .eval(env: env)
    .flatMap {
      (v: Value) in
      .success(env.extend(name: name, value: v))
    }
}

func addDefs(env: Env = Env(values: [:]), defs: Defs) -> Result<Env, Message> {
  return defs.reduce(
    .success(env),
    { (result, def) in
      result.flatMap { env in addDef(env: env, name: def.name, expr: def.expr) }
    }
  )
}

func runProgram(defs: Defs, body: Expr) -> Result<Value, Message> {
  return addDefs(defs: defs)
    .flatMap { env in body.eval(env: env) }
}

func nextName(x: Name) -> Name {
  return x + "'"
}

func freshen(used: [Name], x: Name) -> Name {
  if used.contains(x) {
    return freshen(used: used, x: nextName(x: x))
  }
  return x
}
