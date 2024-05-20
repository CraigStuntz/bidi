import XCTest

@testable import Pie

class ExprTests: XCTestCase {
  func testNotEuqiv() throws {
    let actual = Expr.zero.αEquiv(.absurd)
    XCTAssertFalse(actual)
  }

  func testSimpleEuqiv() throws {
    let actual = Expr.zero.αEquiv(.zero)
    XCTAssertTrue(actual)
  }
}
