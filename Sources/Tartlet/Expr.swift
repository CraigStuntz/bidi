import Shared

public indirect enum Expr: Equatable, Sendable {
  case variable(Name)
  /// Associated type names are x, A, and B as in `(Π ((x A)) B)`
  case pi(Name, Expr, Expr)
  /// Associated type names are x (arg name) and b(ody) as in `(λ (x) b)`
  case lambda(Name, Expr)
  /// Associated type names are (ope)rator and (ope)rand as in `(rator rand)`
  case application(Expr, Expr)
  /// Associated type names are x A and D as in `(Σ ((x A)) D)`
  case sigma(Name, Expr, Expr)
  /// Associated type names are as in `(cons a d)`
  case cons(Expr, Expr)
  /// Associated type is expression as in `(car e)`
  case car(Expr)
  /// Associated type is expression as in `(cdr c)`
  case cdr(Expr)
  case nat
  case zero
  /// Associated type as in `(add1 e)`
  case add1(Expr)
  /// Associated types as in `(ind-Nat tgt mot base step)`
  case indnat(Expr, Expr, Expr, Expr)
  /// Associated types as in `(= A from t)`
  case equal(Expr, Expr, Expr)
  case same
  /// Associated types as in `(replace tgt mot base)`
  case replace(Expr, Expr, Expr)
  case trivial
  case sole
  case absurd
  /// Associated types as in `(ind-Absurd tgt mot)`
  case indabsurd(Expr, Expr)
  case atom
  /// A sumbol, with associated type of the name, as in `'a`
  case tick(String)
  case u
  /// Associated types as in `(the t e)`
  case the(Expr, Expr)

  public func αEquiv(_ other: Expr) -> Bool {
    return αEquivHelper(i: 0, ns1: [], e1: self, ns2: [], e2: other)
  }

  ///   Helper to test for expression equivalence
  ///
  /// - Parameters:
  ///   - i: the numberof variable bindings that have been crossed during the current traversal
  ///   - ns1: namespace that maps names to the depth at which they were bound for e1
  ///   - e1: expression to test for equality
  ///   - ns2: namespace that maps names to the depth at which they were bound for e2
  ///   - e2: expression to test for equality
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
