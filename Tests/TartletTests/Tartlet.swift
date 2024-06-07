import CustomDump
import XCTest

@testable import Tartlet

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

class CtxTests: XCTestCase {
  // These tests are taken from the Racket version of the tutorial; they don't
  // appear in the Haskell version
  let testCtx =
    Ctx
    .toplevel(expressions: [
      (
        "two",
        .the(.nat, .add1(.add1(.zero)))
      ),
      (
        "three",
        .the(.nat, .add1(.add1(.add1(.zero))))
      ),
      (
        "nat=consequence",
        .the(
          .pi("j", .nat, .pi("k", .nat, .u)),
          .lambda(
            "j",
            .lambda(
              "k",
              .indnat(
                .variable("j"),
                .lambda("_", .u),
                .indnat(
                  .variable("k"),
                  .lambda("_", .u),
                  .trivial,
                  .lambda(
                    "_",
                    .lambda(
                      "_",
                      .absurd))),
                .lambda(
                  "j-1",
                  .lambda(
                    "_",
                    .indnat(
                      .variable("k"),
                      .lambda("_", .u),
                      .absurd,
                      .lambda(
                        "k-1",
                        .lambda(
                          "_",
                          .equal(.nat, .variable("j-1"), .variable("k-1")))))))))))
      ),
      (
        "nat=consequence-refl",
        .the(
          .pi(
            "n",
            .nat,
            .application(.application(.variable("nat=consequence"), .variable("n")), .variable("n"))
          ),
          .lambda(
            "n",
            .indnat(
              .variable("n"),
              .lambda(
                "k",
                .application(
                  .application(.variable("nat=consequence"), .variable("k")), .variable("k"))),
              .sole,
              .lambda(
                "n-1",
                .lambda(
                  "_",
                  .same)))))
      ),

      //   ; The consequences hold for all equal Nats
      (
        "there-are-consequences",
        .the(
          .pi(
            "j", .nat,
            .pi(
              "k", .nat,
              .pi(
                "j=k",
                .equal(.nat, .variable("j"), .variable("k")),
                .application(
                  .application(.variable("nat=consequence"), .variable("j")), .variable("k"))))),
          .lambda(
            "j",
            .lambda(
              "k",
              .lambda(
                "j=k",
                .replace(
                  .variable("j=k"),
                  .lambda(
                    "n",
                    .application(
                      .application(.variable("nat=consequence"), .variable("j")), .variable("n"))),
                  .application(.variable("nat=consequence-refl"), .variable("j")))))))
      ),
    ])

  func evaluateInTestCtx(example: Expr) -> TypeAndNormalForm {
    let output = testCtx.toplevel(example: example)
    guard case .success(let result) = output else {
      XCTFail("Evaluation failed: \(output)")
      fatalError("Evaluation failed: \(output)")
    }
    return toTypeAndNormalForm(result)
  }

  struct TypeAndNormalForm {
    let type: Expr
    let normalForm: Expr
  }

  func toTypeAndNormalForm(_ output: [Output]) -> TypeAndNormalForm {
    guard !output.isEmpty else {
      fatalError("Output is empty")
    }
    return switch output[0] {
    case .exampleOutput(.the(let type, let normal)):
      TypeAndNormalForm(type: type, normalForm: normal)
    default: fatalError("Unexpected output: \(output)")
    }
  }

  func testNatConsequencesReflZero() {
    // (nat=consequence-refl zero)
    let given = Expr.application(.variable("nat=consequence-refl"), .zero)

    let actual = evaluateInTestCtx(example: given)

    let expectedType = Expr.trivial
    let expectedNormalForm = Expr.sole
    XCTAssertEqual(expectedType, actual.type)
    XCTAssertEqual(expectedNormalForm, actual.normalForm)

    print("(nat=consequence-refl zero)")
    customDump(actual)
  }

  func testNatConsequencesReflTwo() {
    //   (nat=consequence-refl (add1 (add1 zero)))
    let given = Expr.application(.variable("nat=consequence-refl"), .add1(.add1(.zero)))

    let actual = evaluateInTestCtx(example: given)

    let expectedType = Expr.equal(
      .nat,
      .add1(.zero),
      .add1(.zero)
    )
    let expectedNormalForm = Expr.same
    XCTAssertEqual(expectedType, actual.type)
    XCTAssertEqual(expectedNormalForm, actual.normalForm)

    print("(nat=consequence-refl (add1 (add1 zero)))")
    customDump(actual)
  }

  func testThereAreConsequencesZeroZero() {
    //   ((there-are-consequences zero) zero)
    let given = Expr.application(.application(.variable("there-are-consequences"), .zero), .zero)

    let actual = evaluateInTestCtx(example: given)

    let expectedType = Expr.pi(
      "j=k",
      .equal(
        .nat,
        .zero,
        .zero
      ),
      .trivial
    )
    let expectedNormalForm = Expr.lambda(
      "j=k",
      .sole
    )
    XCTAssertEqual(expectedType, actual.type)
    XCTAssertEqual(expectedNormalForm, actual.normalForm)

    print("((there-are-consequences zero) zero)")
    customDump(actual)
  }

  func testThereAreConsequencesZeroZeroSame() {
    //   (((there-are-consequences zero) zero) sole)
    let given = Expr.application(
      .application(.application(.variable("there-are-consequences"), .zero), .zero), .same)

    let actual = evaluateInTestCtx(example: given)

    let expectedType = Expr.trivial
    let expectedNormalForm = Expr.sole
    XCTAssertEqual(expectedType, actual.type)
    XCTAssertEqual(expectedNormalForm, actual.normalForm)

    print("(((there-are-consequences zero) zero) sole)")
    customDump(actual)
  }

  func testThereAreConsequencesAdd1ZeroAdd1Zero() {
    //   ((there-are-consequences (add1 zero)) (add1 zero))
    let given = Expr.application(
      .application(.variable("there-are-consequences"), .add1(.zero)), .add1(.zero))

    let actual = evaluateInTestCtx(example: given)

    let expectedType = Expr.pi(
      "j=k",
      .equal(
        .nat,
        .add1(.zero),
        .add1(.zero)
      ),
      .equal(
        .nat,
        .zero,
        .zero
      )
    )
    let expectedNormalForm = Expr.lambda(
      "j=k",
      .replace(
        .variable("j=k"),
        .lambda(
          "x",
          .indnat(
            .variable("x"),
            .lambda(
              "k",
              .u
            ),
            .absurd,
            .lambda(
              "n-1",
              .lambda(
                "almost",
                .equal(
                  .nat,
                  .zero,
                  .variable("n-1")))))),
        .same))
    XCTAssertEqual(expectedType, actual.type)
    XCTAssertEqual(expectedNormalForm, actual.normalForm)

    print("((there-are-consequences (add1 zero)) (add1 zero))")
    customDump(actual)
  }

  func testThereAreConsequencesAdd1ZeroAdd1ZeroSame() {
    //   (((there-are-consequences (add1 zero)) (add1 zero)) same)
    let given = Expr.application(
      .application(.application(.variable("there-are-consequences"), .add1(.zero)), .add1(.zero)),
      .same)

    let actual = evaluateInTestCtx(example: given)

    let expectedType = Expr.equal(
      .nat,
      .zero,
      .zero
    )
    let expectedNormalForm = Expr.same
    XCTAssertEqual(expectedType, actual.type)
    XCTAssertEqual(expectedNormalForm, actual.normalForm)

    print("(((there-are-consequences (add1 zero)) (add1 zero)) same)")
    customDump(actual)
  }

  func testThereAreConsequencesZeroAdd1Zero() {
    //   ((there-are-consequences zero) (add1 zero))
    let given = Expr.application(
      .application(.variable("there-are-consequences"), .zero), .add1(.zero))

    let actual = evaluateInTestCtx(example: given)

    let expectedType = Expr.pi(
      "j=k",
      .equal(
        .nat,
        .zero,
        .add1(.zero)
      ),
      .absurd
    )
    let expectedNormalForm = Expr.lambda(
      "j=k",
      .the(
        .absurd,
        .replace(
          .variable("j=k"),
          .lambda(
            "x",
            .indnat(
              .variable("x"),
              .lambda(
                "k",
                .u
              ),
              .trivial,
              .lambda(
                "n-1",
                .lambda(
                  "almost",
                  .absurd)))),
          .sole)))
    XCTAssertEqual(expectedType, actual.type)
    XCTAssertEqual(expectedNormalForm, actual.normalForm)

    print("((there-are-consequences zero) (add1 zero))")
    customDump(actual)
  }

  func testThereAreConsequencesAdd1ZeroZero() {
    //   ((there-are-consequences (add1 zero)) zero))
    let given = Expr.application(
      .application(.variable("there-are-consequences"), .add1(.zero)), .zero)

    let actual = evaluateInTestCtx(example: given)

    let expectedType = Expr.pi(
      "j=k",
      .equal(
        .nat,
        .add1(.zero),
        .zero
      ),
      .absurd
    )
    let expectedNormalForm = Expr.lambda(
      "j=k",
      .the(
        .absurd,
        .replace(
          .variable("j=k"),
          .lambda(
            "x",
            .indnat(
              .variable("x"),
              .lambda(
                "k",
                .u
              ),
              .absurd,
              .lambda(
                "n-1",
                .lambda(
                  "almost",
                  .equal(
                    .nat,
                    .zero,
                    .variable("n-1")
                  )
                )
              )
            )
          ),
          .same
        )
      )
    )
    XCTAssertEqual(expectedType, actual.type)
    XCTAssertEqual(expectedNormalForm, actual.normalForm)

    print("((there-are-consequences (add1 zero)) zero))")
    customDump(actual)
  }
}
