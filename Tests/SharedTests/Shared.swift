import XCTest

@testable import Shared

struct FancyString: Show {
  let value: String

  public func prettyPrint(offsetChars: Int) -> [String] {
    return [value]
  }
}

class EnvTests: XCTestCase {
  func testEnvIsImmutable() throws {
    let env = Env<FancyString>(values: [
      "foo": FancyString(value: "bar")
    ])
    let newEnv = env.extend(
      name: "baz", value: FancyString(value: "qux")
    )

    XCTAssertNotNil(env["foo"])
    XCTAssertNil(env["baz"])
    XCTAssertNotNil(newEnv["foo"])
    XCTAssertNotNil(newEnv["foo"])
  }
}
