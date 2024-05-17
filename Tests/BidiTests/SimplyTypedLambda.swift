import CustomDump
import Shared
import XCTest

@testable import Bidi

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

class SimplyTypedTests: XCTestCase {
  func testPlus() throws {
    let actual = Program(
      namedExprs: testDefs,
      body: .variable("+")
    ).run()

    customDump(actual)
    guard case .success(let expr) = actual else {
      return XCTFail("Expected success, got \(actual)")
    }
    XCTAssertEqual(
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
                .add1(.variable("almostSum"))))))),
      expr)
  }

  func testPlus3() throws {
    let actual = Program(
      namedExprs: testDefs,
      body: .application(.variable("+"), .variable("three"))
    ).run()

    customDump(actual)
    guard case .success(let expr) = actual else {
      return XCTFail("Expected success, got \(actual)")
    }
    XCTAssertEqual(
      .lambda("k", .add1(.add1(.add1(.variable("k"))))), expr
    )
  }

  func testAdd3Plus2() throws {
    let actual = Program(
      namedExprs: testDefs,
      body: .application(.application(.variable("+"), .variable("three")), .variable("two"))
    ).run()

    customDump(actual)
    guard case .success(let expr) = actual else {
      return XCTFail("Expected success, got \(actual)")
    }
    XCTAssertEqual(
      .add1(.add1(.add1(.add1(.add1(.zero))))), expr
    )
  }
}
