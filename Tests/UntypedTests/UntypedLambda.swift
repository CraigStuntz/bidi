import CustomDump
import Testing

@testable import Untyped

let churchDefs: Defs = [
  ("zero", .lambda("f", .lambda("x", .variable("x")))),
  (
    "add1",
    .lambda(
      "n",
      .lambda(
        "f",
        .lambda(
          "x",
          .application(
            .variable("f"),
            .application(
              .application(
                .variable("n"),
                .variable("f")),
              .variable("x"))))))
  ),
  (
    "+",
    .lambda(
      "j",
      .lambda(
        "k",
        .lambda(
          "f",
          .lambda(
            "x",
            .application(
              .application(.variable("j"), .variable("f")),
              .application(
                .application(.variable("k"), .variable("f")),
                .variable("x")))))))
  ),
]

func toChurch(_ n: Int) -> Expr {
  if n <= 0 {
    return .variable("zero")
  }
  return .application(.variable("add1"), toChurch(n - 1))
}

struct UntypedLambdaTests {
  @Test func twoPplus3() throws {
    let actual = Program(
      defs: churchDefs,
      body: .application(.application(.variable("+"), toChurch(2)), toChurch(3))
    ).run()

    customDump(actual)
    guard case .success(let expr) = actual else {
      Issue.record("Expected success, got \(actual)")
      return
    }
    #expect(
      .lambda(
        "f",
        .lambda(
          "x",
          .application(
            .variable("f"),
            .application(
              .variable("f"),
              .application(
                .variable("f"),
                .application(
                  .variable("f"),
                  .application(
                    .variable("f"),
                    .variable("x")))))))) == expr)
  }

  @Test func twoPlus3WithBug() throws {
    let result = Program(
      defs: [],
      body: .application(.application(.variable("+"), toChurch(2)), toChurch(3))
    ).run()
    switch result {
    case .success:
      Issue.record()
      return
    case .failure(let message):
      switch message {
      case .notFound(let name):
        #expect("+" == name)
      }
    }
  }
}
