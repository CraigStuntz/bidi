import XCTest

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

func test() -> Result<Expr, Message> {
  return Program(
    defs: churchDefs,
    body: .application(.application(.variable("+"), toChurch(2)), toChurch(3))
  ).run()
}

func testFail() -> Result<Expr, Message> {
  return Program(
    defs: [],
    body: .application(.application(.variable("+"), toChurch(2)), toChurch(3))
  ).run()
}

class UntypedLambdaTests: XCTestCase {
  func test2plus3() throws {
    let result = test()
    let actual = try result.get()
    print(actual)
  }

  func test2plus3WithBug() throws {
    let result = testFail()
    switch result {
    case .success:
      XCTFail()
    case .failure(let message):
      switch message {
      case .notFound(let name):
        XCTAssertEqual("+", name)
      }
    }
  }
}
