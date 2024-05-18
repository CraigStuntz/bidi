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
  case sigma(Name, Expr)
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
}
