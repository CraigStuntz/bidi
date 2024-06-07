import Shared

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
