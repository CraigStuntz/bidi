typealias Name = String

struct Env {
  let values: [Name: Value]
  let isEmpty: Bool

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
    self.isEmpty = self.values.isEmpty
  }
}

enum Message: Error {
  case notFound(Name)
}

protocol Value {
  func apply(argValue: Value) -> Result<Value, Message>
}

struct VClosure: Value {
  let env: Env
  let argName: Name
  let body: Expr

  func apply(argValue: Value) -> Result<Value, Message> {
    return body.eval(env: self.env.extend(name: argName, value: argValue))
  }
}

func mapToResult(maybeVal: Value?, orElse: Message) -> Result<Value, Message> {
  guard let value = maybeVal else {
    return .failure(orElse)
  }
  return .success(value)
}

indirect enum Expr {
  case variable(Name)
  case lambda(Name, Expr)
  case application(Expr, Expr)

  func eval(env: Env) -> Result<Value, Message> {
    switch self {
    case let .variable(name):
      return mapToResult(maybeVal: env[name], orElse: .notFound(name))
    case let .lambda(name, body):
      return .success(VClosure(env: env, argName: name, body: body))
    // "The names rator and rand are short for 'operator' and 'operand.'
    //  These names go back to Landin (1964).""
    case let .application(rator, rand):
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
}

typealias Defs = [Name: Expr]

func addDef(env: Env, name: Name, expr: Expr) -> Result<Env, Message> {
  return
    expr
    .eval(env: env)
    .flatMap {
      (v: Value) in
      .success(env.extend(name: name, value: v))
    }
}

func addDefs(env: Env, defs: Defs) -> Result<Env, Message> {
  return defs.reduce(
    .success(env),
    { (accum, def) in
      accum.flatMap { env in return addDef(env: env, name: def.key, expr: def.value) }
    }
  )
}

func runProgram(defs: Defs, expr: Expr) -> Result<Value, Message> {
  return addDefs(env: Env(values: [:]), defs: defs)
    .flatMap { (env: Env) in expr.eval(env: env) }
}
