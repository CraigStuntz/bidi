import XCTest

@testable import Shared

class EnvTests: XCTestCase {
  func testEnvIsImmutable() throws {
    let env = [
      "foo": "bar"
    ]
    let newEnv = env.extend(
      name: "baz", value: "qux"
    )

    XCTAssertNotNil(env["foo"])
    XCTAssertNil(env["baz"])
    XCTAssertNotNil(newEnv["foo"])
    XCTAssertNotNil(newEnv["foo"])
  }
}
