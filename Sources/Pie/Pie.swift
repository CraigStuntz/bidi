import Shared

public indirect enum Expr {
  case variable(Name)
  /// Associated type names are x, A, and B as in (Π ((x A)) B)
  case pi(Name, Expr, Expr)
  /// Associated type names are x (arg name) and b(ody) as in (λ (x) b)
  case lambda(Name, Expr)
  /// Associated type names are (ope)rator and (ope)rand as in (rator rand)
  case application(Expr, Expr)
  /// Associated type names are x A and D as in (Σ ((x A)) D)
  case sigma(Name, Expr, Expr)
  /// Associated type names are as in (cons a d)
  case cons(Expr, Expr)
  /// Associated type is expression as in (car e)
  case car(Expr)
  /// Associated type is expression as in (cdr c)
  case cdr(Expr)
  case nat
  case zero
  /// Associated type as in (add1 e)
  case add1(Expr)
  /// Associated types as in (ind-Nat tgt mot base step)
  case indnat(Expr, Expr, Expr, Expr)
  /// Associated types as in (= A from t)
  case equal(Expr, Expr, Expr)
  case same
  /// Associated types as in (replace tgt mot base)
  case replace(Expr, Expr, Expr)
  case trivial
  case sole
  case absurd
  /// Associated types as in (ind-Absurd tgt mot)
  case indabsurd(Expr, Expr)
  case atom
  /// 'a'
  case tick(String)
  case u
  /// Associated types as in (the t e)
  case the(Expr, Expr)

  public func αEquiv(_ other: Expr) -> Bool {
    return αEquivHelper(i: 0, ns1: [], e1: self, ns2: [], e2: other)
  }

  ///   Helper to test for expression equivalence
  ///
  /// - Parameter i: the numberof variable bindings that have been crossed during the current traversal
  /// - Parameter ns1: namespace that maps names to the depth at which they were bound for e1
  /// - Parameter e1: expression to test for equality
  /// - Parameter ns2: namespace that maps names to the depth at which they were bound for e2
  /// - Parameter e2: expression to test for equality
  /// - Returns: True, if equivalent. False if not.
  func αEquivHelper(i: Int, ns1: [(Name, Int)], e1: Expr, ns2: [(Name, Int)], e2: Expr) -> Bool {
    switch (e1, e2) {
    case (.variable(let x), .variable(let y)):
      return switch (ns1.lookup(x), ns2.lookup(y)) {
      case (.none, .none): x == y
      case (.some(let si), .some(let sj)): si == sj
      default: false
      }
    case (.pi(let x, let a1, let r1), .pi(let y, let a2, let r2)):
      return αEquivHelper(i: i, ns1: ns1, e1: a1, ns2: ns2, e2: a2)
        && αEquivHelper(
          i: i + 1,
          ns1: Array(head: (x, i), rest: ns1), e1: r1,
          ns2: Array(head: (y, i), rest: ns2), e2: r2)
    case (.lambda(let x, let body1), .lambda(let y, let body2)):
      return αEquivHelper(
        i: i + 1,
        ns1: Array(head: (x, i), rest: ns1), e1: body1,
        ns2: Array(head: (y, i), rest: ns2), e2: body2)
    case (.application(let rator1, let rand1), .application(let rator2, let rand2)):
      return αEquivHelper(i: i, ns1: ns1, e1: rator1, ns2: ns2, e2: rator2)
        && αEquivHelper(i: i, ns1: ns1, e1: rand1, ns2: ns2, e2: rand2)
    case (.sigma(let x, let a1, let d1), .sigma(let y, let a2, let d2)):
      return αEquivHelper(i: i, ns1: ns1, e1: a1, ns2: ns2, e2: a2)
        && αEquivHelper(
          i: i + 1,
          ns1: Array(head: (x, i), rest: ns1), e1: d1,
          ns2: Array(head: (y, i), rest: ns2), e2: d2)
    case (.cons(let car1, let cdr1), .cons(let car2, let cdr2)):
      return αEquivHelper(i: i, ns1: ns1, e1: car1, ns2: ns2, e2: car2)
        && αEquivHelper(i: i, ns1: ns1, e1: cdr1, ns2: ns2, e2: cdr2)
    case (.car(let pair1), .car(let pair2)):
      return αEquivHelper(i: i, ns1: ns1, e1: pair1, ns2: ns2, e2: pair2)
    case (.cdr(let pair1), .cdr(let pair2)):
      return αEquivHelper(i: i, ns1: ns1, e1: pair1, ns2: ns2, e2: pair2)
    case (.nat, .nat): return true
    case (.zero, .zero): return true
    case (.add1(let ex1), .add1(let ex2)):
      return αEquivHelper(i: 1, ns1: ns1, e1: ex1, ns2: ns2, e2: ex2)
    case (
      .indnat(let tgt1, let mot1, let base1, let step1),
      .indnat(let tgt2, let mot2, let base2, let step2)
    ):
      return αEquivHelper(i: i, ns1: ns1, e1: tgt1, ns2: ns2, e2: tgt2)
        && αEquivHelper(i: i, ns1: ns1, e1: mot1, ns2: ns2, e2: mot2)
        && αEquivHelper(i: i, ns1: ns1, e1: base1, ns2: ns2, e2: base2)
        && αEquivHelper(i: i, ns1: ns1, e1: step1, ns2: ns2, e2: step2)
    case (.equal(let ty1, let from1, let to1), .equal(let ty2, let from2, let to2)):
      return αEquivHelper(i: i, ns1: ns1, e1: ty1, ns2: ns2, e2: ty2)
        && αEquivHelper(i: i, ns1: ns1, e1: from1, ns2: ns2, e2: from2)
        && αEquivHelper(i: i, ns1: ns1, e1: to1, ns2: ns2, e2: to2)
    case (.same, .same): return true
    case (.replace(let tgt1, let mot1, let base1), .replace(let tgt2, let mot2, let base2)):
      return αEquivHelper(i: i, ns1: ns1, e1: tgt1, ns2: ns2, e2: tgt2)
        && αEquivHelper(i: i, ns1: ns1, e1: mot1, ns2: ns2, e2: mot2)
        && αEquivHelper(i: i, ns1: ns1, e1: base1, ns2: ns2, e2: base2)
    case (.trivial, .trivial): return true
    case (.sole, .sole): return true
    case (.absurd, .absurd): return true
    case (.indabsurd(let tgt1, let mot1), .indabsurd(let tgt2, let mot2)):
      return αEquivHelper(i: i, ns1: ns1, e1: tgt1, ns2: ns2, e2: tgt2)
        && αEquivHelper(i: i, ns1: ns1, e1: mot1, ns2: ns2, e2: mot2)
    case (.atom, .atom): return true
    case (.u, .u): return true
    case (.tick(let a1), .tick(let a2)): return a1 == a2
    case (.the(.absurd, _), .the(.absurd, _)): return true
    case (.the(let t1, let ex1), .the(let t2, let ex2)):
      return αEquivHelper(i: i, ns1: ns1, e1: t1, ns2: ns2, e2: t2)
        && αEquivHelper(i: i, ns1: ns1, e1: ex1, ns2: ns2, e2: ex2)
    default: return false
    }
  }
}

public typealias Env = [(Name, Value)]

extension Env {
  public func eval(_ expr: Expr) -> Value {
    switch expr {
    case .variable(let name): return evalVar(name)
    case .pi(let x, let dom, let ran):
      return .vpi(eval(dom), Closure(env: self, name: x, body: ran))
    case .lambda(let x, let body): return .vlambda(Closure(env: self, name: x, body: body))
    case .application(let rator, let rand): return eval(rator).doApply(arg: eval(rand))
    case .sigma(let x, let carType, let cdrType):
      return .vsigma(eval(carType), Closure(env: self, name: x, body: cdrType))
    case .cons(let a, let d): return .vpair(eval(a), eval(d))
    case .car(let e): return eval(e).doCar()
    case .cdr(let e): return eval(e).doCdr()
    case .nat: return .vnat
    case .zero: return .vzero
    case .add1(let e): return .vadd1(eval(e))
    case .indnat(let tgt, let mot, let base, let step):
      return eval(tgt).doIndNat(mot: eval(mot), base: eval(base), step: eval(step))
    case .equal(let ty, let from, let to): return .veq(eval(ty), eval(from), eval(to))
    case .same: return .vsame
    case .replace(let tgt, let mot, let base):
      return eval(tgt).doReplace(mot: eval(mot), base: eval(base))
    case .trivial: return .vtrivial
    case .sole: return .vsole
    case .absurd: return .vabsurd
    case .indabsurd(let tgt, let mot): return eval(tgt).doIndAbsurd(mot: eval(mot))
    case .atom: return .vatom
    case .tick(let x): return .vtick(x)
    case .u: return .vu
    case .the(_, let e): return eval(e)
    }
  }

  public func evalVar(_ name: Name) -> Value {
    return switch lookup(name) {
    case .some(let value): value
    case .none: fatalError("Missing value for \(name)")
    }
  }

  func extend(name: Name, value: Value) -> Env {
    var result = Env()
    result.append((name, value))
    result.append(contentsOf: self)
    return result
  }

  public func lookup(_ name: Name) -> Value? {
    return first(where: { (n, _) in n == name }).map { (_, v) in v }
  }

  // THis is `mkEnv` in David's tutorial
  public init(ctx: Ctx) {
    self.init(
      ctx.map { (name, ctxEntry) in
        let value: Value =
          switch ctxEntry {
          case .def(_, let val): val
          case .isa(let type): Value.vneutral(type, .nvar(name))
          }
        return (name, value)
      })
  }
}

public enum Message: Error, CustomStringConvertible {
  case unboundVariable(Name)

  public var description: String {
    switch self {
    case .unboundVariable(let name): "Unbound variable: \(name)"
    }
  }
}

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

  func indNatStepType(_ mot: Value) -> Value {
    return Env([("mot", mot)]).eval(
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
    case .vadd1(let v):
      step.doApply(arg: v).doApply(arg: v.doIndNat(mot: mot, base: base, step: step))
    case .vneutral(.vnat, let neu):
      .vneutral(
        mot.doApply(arg: self),
        .nindnat(
          neu,
          Normal(type: .vpi(.vnat, Closure(env: Env(), name: "k", body: .u)), value: mot),
          Normal(type: mot.doApply(arg: .vzero), value: base),
          Normal(type: indNatStepType(mot), value: step)))
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

public enum CtxEntry {
  case def(Type, Value)
  case isa(Type)
}

public typealias Ctx = [(Name, CtxEntry)]

extension Ctx {
  public func define(name: Name, type: Type, value: Value) -> Ctx {
    return prepend(name: name, ctxEntry: .def(type, value))
  }

  public func extend(name: Name, type: Type) -> Ctx {
    return prepend(name: name, ctxEntry: .isa(type))
  }

  public func lookupType(name: Name) -> Result<Type, Message> {
    switch first(where: { (n, _) in n == name }) {
    case .none: return .failure(.unboundVariable(name))
    case .some((_, .def(let t, _))): return .success(t)
    case .some((_, .isa(let t))): return .success(t)
    }
  }

  func prepend(name: Name, ctxEntry: CtxEntry) -> Ctx {
    var result = Ctx()
    result.append((name, ctxEntry))
    result.append(contentsOf: self)
    return result
  }

  public func readBack(neutral: Neutral) -> Expr {
    return switch neutral {
    case .nvar(let x): .variable(x)
    case .napp(let neu, let arg): .application(readBack(neutral: neu), readBack(normal: arg))
    case .ncar(let neu): .car(readBack(neutral: neu))
    case .ncdr(let neu): .cdr(readBack(neutral: neu))
    case .nindnat(let neu, let mot, let base, let step):
      .indnat(
        readBack(neutral: neu),
        readBack(normal: mot),
        readBack(normal: base),
        readBack(normal: step))
    case .nreplace(let neu, let mot, let base):
      .replace(
        readBack(neutral: neu),
        readBack(normal: mot),
        readBack(normal: base))
    case .nindabsurd(let neu, let mot):
      .indabsurd(
        .the(.absurd, readBack(neutral: neu)),
        readBack(normal: mot))
    }
  }

  public func readBack(normal: Normal) -> Expr {
    return readBack(type: normal.type, value: normal.value)
  }

  func readBack(type: Type, value: Value) -> Expr {
    switch (type, value) {
    case (.vnat, .vzero): return .zero
    case (.vnat, .vadd1(let v)): return .add1(readBack(type: .vnat, value: v))
    case (.vpi(let dom, let ran), let fun):
      let x = names.freshen(x: ran.name)
      let xVal = Value.vneutral(dom, .nvar(x))
      return .lambda(
        x,
        extend(name: x, type: dom)
          .readBack(type: ran.eval(value: xVal), value: fun.doApply(arg: xVal)))
    case (.vsigma(let aT, let dT), let pair):
      return .cons(
        readBack(type: aT, value: pair.doCar()),
        readBack(type: dT.eval(value: pair.doCar()), value: pair.doCdr()))
    case (.vtrivial, _): return .sole
    case (.vabsurd, .vneutral(.vabsurd, let neu)): return .the(.absurd, readBack(neutral: neu))
    case (.veq, .vsame): return .same
    case (.vatom, .vtick(let x)): return .tick(x)
    case (.vu, .vnat): return .nat
    case (.vu, .vatom): return .atom
    case (.vu, .vtrivial): return .trivial
    case (.vu, .vabsurd): return .absurd
    case (.vu, .veq(let t, let from, let to)):
      return .equal(
        readBack(type: .vu, value: t),
        readBack(type: t, value: from),
        readBack(type: t, value: to))
    case (.vu, .vsigma(let aT, let dT)):
      let x = names.freshen(x: dT.name)
      return .sigma(
        x,
        readBack(type: .vu, value: aT),
        extend(name: x, type: aT)
          .readBack(type: .vu, value: dT.eval(value: .vneutral(aT, .nvar(x)))))
    case (.vu, .vpi(let aT, let bT)):
      let x = names.freshen(x: bT.name)
      return .pi(
        x,
        readBack(type: .vu, value: aT),
        extend(name: x, type: aT)
          .readBack(type: .vu, value: bT.eval(value: .vneutral(aT, .nvar(x)))))
    case (.vu, .vu): return .u
    case (_, .vneutral(_, let neu)): return readBack(neutral: neu)
    default: fatalError("Internal error, not expecting \(type) and \(value) here.")
    }
  }

  public var names: [Name] {
    return map { (name, _) in name }
  }
}
