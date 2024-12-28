import Testing

@testable import Shared

struct EnvTests {
  @Test func envIsImmutable() throws {
    let env = [
      "foo": "bar"
    ]
    let newEnv = env.extend(
      name: "baz", value: "qux"
    )

    #expect(env["foo"] != nil)
    #expect(env["baz"] == nil)
    #expect(newEnv["foo"] != nil)
    #expect(newEnv["foo"] != nil)
  }
}
