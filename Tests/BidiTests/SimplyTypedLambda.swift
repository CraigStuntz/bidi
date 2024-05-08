import CustomDump
import XCTest

@testable import Bidi

let testDefs: Defs = [
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
  func testAdd() throws {
    let actual: Result<(Type, Type), Message> = Program.addDefs(testDefs).flatMap { ctx in
      ctx.synth(expr: .application(.variable("+"), .variable("three"))).flatMap { t1 in
        ctx.synth(
          expr: .application(.application(.variable("+"), .variable("three")), .variable("two"))
        ).flatMap { t2 in
          .success((t1, t2))
        }
      }
    }
    guard case .success((let t1, let t2)) = actual else {
      return XCTFail("Expected success, got \(actual)")
    }
    XCTAssertEqual(.tarr(.tnat, .tnat), t1)
    XCTAssertEqual(.tnat, t2)
    customDump(actual)
  }
}
