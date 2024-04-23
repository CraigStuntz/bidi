import XCTest

@testable import bidi

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
  return runProgram(
    defs: churchDefs,
    body: .application(.application(.variable("+"), toChurch(2)), toChurch(3)))
}

func testFail() -> Result<Expr, Message> {
  return runProgram(
    defs: [],
    body: .application(.application(.variable("+"), toChurch(2)), toChurch(3)))
}

class EnvTests: XCTestCase {
  func testEnvIsImmutable() throws {
    let env = Env(values: [
      "foo": VClosure(env: Env(values: [:]), argName: "bar", body: .variable("x"))
    ])
    let newEnv = env.extend(
      name: "baz", value: VClosure(env: Env(values: [:]), argName: "qux", body: .variable("boo")))

    XCTAssertNotNil(env["foo"])
    XCTAssertNil(env["baz"])
    XCTAssertNotNil(newEnv["foo"])
    XCTAssertNotNil(newEnv["foo"])
  }
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
