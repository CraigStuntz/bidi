import Foundation

public typealias Name = String

extension Dictionary {
  public func extend(name: Key, value: Value) -> [Key: Value] {
    var result = self
    result[name] = value
    return result
  }
}
