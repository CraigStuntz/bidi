import Foundation

public typealias Name = String

let indent = 2

public func padding(chars: Int) -> String {
  return "".padding(toLength: chars, withPad: " ", startingAt: 0)
}

let tab = padding(chars: indent)

public protocol Show: CustomStringConvertible {
  func prettyPrint(offsetChars: Int) -> [String]
}

extension Show {
  public var description: String {
    let result = prettyPrint(offsetChars: indent)
    return String(result.joined(separator: "\n"))
  }
}

public struct Env<Element: Show> {
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

  public func prettyPrint(offsetChars: Int) -> [String] {
    var result: [String] = []
    let leftPad = padding(chars: offsetChars)
    for key in values.keys.sorted() {
      result.append("\(leftPad)\(tab)(\(key)")
      if let value = values[key] {
        result.append(contentsOf: value.prettyPrint(offsetChars: offsetChars + indent + indent))
      }
      result.append("\(leftPad)\(tab))")
    }
    return result
  }
}
