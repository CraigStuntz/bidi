import Shared

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

  public func synth(expr: Expr) -> Result<Type, Message> {
    switch expr {
    case .variable(let x): return lookupType(name: x)
    case .pi(let x, let a, let b):
      return check(expr: a, type: .vu)
        .flatMap { extend(name: x, type: Env(ctx: self).eval(a)).check(expr: b, type: .vu) }
        .map { .vu }
    case .application(let rator, let rand):
      return synth(expr: rator)
        .flatMap { funTy in
          isPi(funTy)
            .flatMap { (a, b) in
              check(expr: rand, type: a)
                .map { b.eval(value: Env(ctx: self).eval(rand)) }
            }
        }
    case .sigma(let x, let a, let b):
      return check(expr: a, type: .vu)
        .flatMap {
          extend(name: x, type: Env(ctx: self).eval(a))
            .check(expr: b, type: .vu)
            .map { .vu }
        }
    case .car(let e):
      return synth(expr: e)
        .flatMap { t in
          isSigma(t).map { (aT, _) in aT }
        }
    case .cdr(let e):
      return synth(expr: e)
        .flatMap { t in
          isSigma(t)
            .map { (aT, dT) in
              dT.eval(value: Env(ctx: self).eval(e).doCar())
            }
        }
    case .nat:
      return .success(.vu)
    case .indnat(let tgt, let mot, let base, let step):
      return synth(expr: tgt)
        .flatMap { t in
          isNat(t)
            .flatMap {
              let tgtV = Env(ctx: self).eval(tgt)
              let motV = Env(ctx: self).eval(mot)
              return check(expr: base, type: motV.doApply(arg: .vzero))
                .flatMap {
                  check(expr: step, type: motV.indNatStepType())
                    .map { motV.doApply(arg: tgtV) }
                }
            }
        }
    case .equal(let type, let from, let to):
      return check(expr: type, type: .vu)
        .flatMap {
          let tyV = Env(ctx: self).eval(type)
          return check(expr: from, type: tyV)
            .flatMap {
              check(expr: to, type: tyV)
                .map { .vu }
            }
        }
    case .replace(let tgt, let mot, let base):
      return synth(expr: tgt)
        .flatMap { t in
          isEqual(t)
            .flatMap { (ty, from, to) in
              let motTy = Env([("ty", ty)]).eval(.pi("x", .variable("ty"), .u))
              return check(expr: mot, type: motTy)
                .flatMap {
                  let motV = Env(ctx: self).eval(mot)
                  return check(expr: base, type: motV.doApply(arg: from))
                    .map { motV.doApply(arg: to) }
                }
            }
        }
    case .trivial:
      return .success(.vu)
    case .absurd:
      return .success(.vu)
    case .indabsurd(let tgt, let mot):
      return synth(expr: tgt)
        .flatMap { t in
          isAbsurd(t)
            .flatMap {
              check(expr: mot, type: .vu)
                .map { Env(ctx: self).eval(mot) }
            }
        }
    case .atom:
      return .success(.vu)
    case .u:
      return .success(.vu)
    case .the(let ty, let exp):
      return check(expr: ty, type: .vu)
        .flatMap {
          let tyV = Env(ctx: self).eval(ty)
          return check(expr: exp, type: tyV)
            .map { tyV }
        }
    default:
      return .failure(.cannotSynthesize(expr))
    }
  }

  public func check(expr: Expr, type: Type) -> Result<(), Message> {
    switch expr {
    case .lambda(let x, let body):
      return isPi(type)
        .flatMap { (a, b) in
          let xV = b.eval(value: .vneutral(a, .nvar(x)))
          return extend(name: x, type: a)
            .check(expr: body, type: xV)
        }
    case .cons(let a, let d):
      return isSigma(type)
        .flatMap { (aT, dT) in
          check(expr: a, type: aT)
            .flatMap {
              let aV = Env(ctx: self).eval(a)
              return check(expr: d, type: dT.eval(value: aV))
            }
        }
    case .zero:
      return isNat(type)
    case .add1(let n):
      return isNat(type)
        .flatMap {
          check(expr: n, type: .vnat)
        }
    case .same:
      return isEqual(type)
        .flatMap { (t, from, to) in
          convert(type: t, v1: from, v2: to)
        }
    case .sole:
      return isTrivial(type)
    case .tick:
      return isAtom(type)
    default:
      return synth(expr: expr)
        .flatMap { t in
          convert(type: .vu, v1: t, v2: type)
        }
    }
  }

  func convert(type: Type, v1: Value, v2: Value) -> Result<(), Message> {
    let e1 = readBack(type: type, value: v1)
    let e2 = readBack(type: type, value: v2)
    if e1.αEquiv(e2) {
      return .success(())
    }
    return .failure(.notSameType(e1, e2))
  }

  func isPi(_ value: Value) -> Result<(Type, Closure), Message> {
    return switch value {
    case .vpi(let a, let b): .success((a, b))
    default: .failure(unexpected(msg: .incorrectType(".pi"), t: value))
    }
  }

  func isSigma(_ value: Value) -> Result<(Type, Closure), Message> {
    return switch value {
    case .vsigma(let a, let b): .success((a, b))
    default: .failure(unexpected(msg: .incorrectType(".vsigma"), t: value))
    }
  }

  func isNat(_ value: Value) -> Result<(), Message> {
    return switch value {
    case .vnat: .success(())
    default: .failure(unexpected(msg: .incorrectType(".vnat"), t: value))
    }
  }

  func isEqual(_ value: Value) -> Result<(Type, Value, Value), Message> {
    return switch value {
    case .veq(let type, let from, let to): .success((type, from, to))
    default: .failure(unexpected(msg: .incorrectType(".veq"), t: value))
    }
  }

  func isAbsurd(_ value: Value) -> Result<(), Message> {
    return switch value {
    case .vabsurd: .success(())
    default: .failure(unexpected(msg: .incorrectType(".vabsurd"), t: value))
    }
  }

  func isTrivial(_ value: Value) -> Result<(), Message> {
    return switch value {
    case .vtrivial: .success(())
    default: .failure(unexpected(msg: .incorrectType(".vtrivial"), t: value))
    }
  }

  func isAtom(_ value: Value) -> Result<(), Message> {
    return switch value {
    case .vatom: .success(())
    default: .failure(unexpected(msg: .incorrectType(".vatom"), t: value))
    }
  }

  func unexpected(msg: Message, t: Value) -> Message {
    let e = readBack(type: .vu, value: t)
    return .unexpected(msg, e)
  }

  public var names: [Name] {
    return map { (name, _) in name }
  }

  public func toplevel(name: Name, expr: Expr) -> Result<Ctx, Message> {
    switch lookupType(name: name) {
    case .success: return .failure(.alreadyDefined(name))
    case .failure:
      return synth(expr: expr)
        .map { t in
          let v = Env(ctx: self).eval(expr)
          return define(name: name, type: t, value: v)
        }
    }
  }

  public static func toplevel(expressions: [(Name, Expr)]) -> Ctx {
    return expressions.reduce(
      Ctx(),
      { ctx, namedExpr in
        let (name, expr) = namedExpr
        switch ctx.synth(expr: expr) {
        case .success(let type):
          let v = Env(ctx: ctx).eval(expr)
          return ctx.define(name: name, type: type, value: v)
        case .failure(let message):
          fatalError("Top-level expression failed to synthesize type with message \(message)")
        }
      })
  }

  public func toplevel(example: Expr) -> Result<[Output], Message> {
    return synth(expr: example)
      .map { t in
        let v = Env(ctx: self).eval(example)
        let e2 = readBack(type: t, value: v)
        let t2 = readBack(type: .vu, value: t)
        return [.exampleOutput(.the(t2, e2))]
      }
  }
}

public enum Output: Equatable {
  case exampleOutput(Expr)
}
