import XCTest

@testable import bidi

let churchDefs: Defs = [
  "zero": .lambda("f", .lambda("x", .variable("x"))),
  "add1": .lambda(
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
            .variable("x")))))),
  "+": .lambda(
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
              .variable("x"))))))),
]

func toChurch(_ n: Int) -> Expr {
  guard n <= 0 else {
    return .application(.variable("add1"), (toChurch(n - 1)))
  }
  return .variable("zero")
}

func test() -> Result<Value, Message> {
  return runProgram(
    defs: churchDefs,
    expr: .application(.application(.variable("+"), toChurch(2)), toChurch(3)))
}

class UntypedLambdaTests: XCTestCase {
  func test2plus3() throws {
    let result = test()
    let actual = try result.get()
    print(actual)
  }
}
