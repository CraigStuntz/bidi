import Shared

public typealias Type = Value

public indirect enum Value {
  case vpi(Type, Closure)
  case vlambda(Closure)
  case vsigma(Type, Closure)
  case vpair(Value, Value)
  case vnat
  case vzero
  case vadd1(Value)
  case veq(Type, Value, Value)
  case vsame
  case vtrivial
  case vsole
  case vabsurd
  case vatom
  case vtick(String)
  case vu
  case vneutral(Type, Neutral)

  func indNatStepType() -> Value {
    return Env([("mot", self)]).eval(
      .pi(
        "n-1", .nat,
        .pi(
          "almost",
          .application(.variable("mot"), .variable("n-1")),
          .application(.variable("mot"), .add1(.variable("n-1"))))))
  }

  func doApply(arg: Value) -> Value {
    return switch self {
    case .vlambda(let closure): closure.eval(value: arg)
    case .vneutral(.vpi(let dom, let ran), let neu):
      .vneutral(ran.eval(value: arg), .napp(neu, Normal(type: dom, value: arg)))
    default: fatalError("Internal error: Not expecting \(self) here")
    }
  }

  func doCar() -> Value {
    return switch self {
    case .vpair(let v1, _): v1
    case .vneutral(.vsigma(let aT, _), let neu): .vneutral(aT, .ncar(neu))
    default: fatalError("Internal error: Not expecting \(self) here")
    }
  }

  func doCdr() -> Value {
    return switch self {
    case .vpair(_, let v2): v2
    case .vneutral(.vsigma(_, let dT), let neu): .vneutral(dT.eval(value: self.doCar()), .ncdr(neu))
    default: fatalError("Internal error: Not expecting \(self) here")
    }
  }

  func doIndAbsurd(mot: Value) -> Value {
    return switch self {
    case .vneutral(.vabsurd, let neu):
      .vneutral(mot, .nindabsurd(neu, Normal(type: .vu, value: mot)))
    default: fatalError("Internal error: Not expecting \(self) here")
    }
  }

  func doIndNat(mot: Value, base: Value, step: Value) -> Value {
    return switch self {
    case .vzero: base
    case .vadd1(let v):
      step.doApply(arg: v).doApply(arg: v.doIndNat(mot: mot, base: base, step: step))
    case .vneutral(.vnat, let neu):
      .vneutral(
        mot.doApply(arg: self),
        .nindnat(
          neu,
          Normal(type: .vpi(.vnat, Closure(env: Env(), name: "k", body: .u)), value: mot),
          Normal(type: mot.doApply(arg: .vzero), value: base),
          Normal(type: mot.indNatStepType(), value: step)))
    default: fatalError("Internal error: Not expecting \(self) here")
    }
  }

  func doReplace(mot: Value, base: Value) -> Value {
    switch self {
    case .vsame: return base
    case .vneutral(.veq(let ty, let from, let to), let neu):
      let motT = Value.vpi(ty, Closure(env: Env(), name: "x", body: .u))
      let baseT = mot.doApply(arg: from)
      return .vneutral(
        mot.doApply(arg: to),
        .nreplace(neu, Normal(type: motT, value: mot), Normal(type: baseT, value: base)))
    default: fatalError("Internal error: Not expecting \(self) here")
    }
  }
}

public struct Closure {
  let env: Env
  let name: Name
  let body: Expr

  public init(env: Env, name: Name, body: Expr) {
    self.env = env
    self.name = name
    self.body = body
  }

  public func eval(value: Value) -> Value {
    return env.extend(name: name, value: value).eval(body)
  }
}

public indirect enum Neutral {
  case nvar(Name)
  case napp(Neutral, Normal)
  case ncar(Neutral)
  case ncdr(Neutral)
  case nindnat(Neutral, Normal, Normal, Normal)
  case nreplace(Neutral, Normal, Normal)
  case nindabsurd(Neutral, Normal)
}

public struct Normal {
  let type: Type
  let value: Value
}
