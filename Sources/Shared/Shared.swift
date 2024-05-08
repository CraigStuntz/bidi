import Foundation

public typealias Name = String

public struct Env<Element> {
  let values: [Name: Element]

  public subscript(name: Name) -> Element? {
    return self.values[name]
  }

  public func extend(name: Name, value: Element) -> Env {
    var result = values
    result[name] = value
    return Env(values: result)
  }

  init(values: [Name: Element]) {
    self.values = values
  }

  public init() {
    self.init(values: [:])
  }
}
