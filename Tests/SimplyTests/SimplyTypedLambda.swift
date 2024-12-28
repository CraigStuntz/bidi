import CustomDump
import Shared
import Testing

@testable import Simply

let testDefs: [(name: Name, expr: Expr)] = [
  (
    "two",
    .annotation(.add1(.add1(.zero)), .tnat)
  ),
  (
    "three",
    .annotation(.add1(.add1(.add1(.zero))), .tnat)
  ),
  (
    "+",
    .annotation(
      .lambda(
        "n",
        .lambda(
          "k",
          .recursion(
            .tnat, .variable("n"),
            .variable("k"),
            .lambda(
              "pred",
              .lambda("almostSum", .add1(.variable("almostSum"))))))),
      .tarr(.tnat, .tarr(.tnat, .tnat)))
  ),
]

struct SimplyTypedTests {
  @Test func plus() throws {
    let actual = Program(
      namedExprs: testDefs,
      body: .variable("+")
    ).run()

    customDump(actual)
    guard case .success(let expr) = actual else {
      Issue.record("Expected success, got \(actual)")
      return
    }
    #expect(
      .lambda(
        "n",
        .lambda(
          "k",
          .recursion(
            .tnat, .variable("n"),
            .variable("k"),
            .lambda(
              "pred",
              .lambda(
                "almostSum",
                .add1(.variable("almostSum"))))))) == expr)
  }

  @Test func plus3() throws {
    let actual = Program(
      namedExprs: testDefs,
      body: .application(.variable("+"), .variable("three"))
    ).run()

    customDump(actual)
    guard case .success(let expr) = actual else {
      Issue.record("Expected success, got \(actual)")
      return
    }
    #expect(
      .lambda("k", .add1(.add1(.add1(.variable("k"))))) == expr
    )
  }

  @Test func add3Plus2() throws {
    let actual = Program(
      namedExprs: testDefs,
      body: .application(.application(.variable("+"), .variable("three")), .variable("two"))
    ).run()

    customDump(actual)
    guard case .success(let expr) = actual else {
      Issue.record("Expected success, got \(actual)")
      return
    }
    #expect(
      .add1(.add1(.add1(.add1(.add1(.zero))))) == expr
    )
  }
}
