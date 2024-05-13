import Foundation

public typealias Name = String

extension Dictionary {
  public func extend(name: Key, value: Value) -> [Key: Value] {
    var result = self
    result[name] = value
    return result
  }
}

extension [String] {
  private func nextName(x: Name) -> Name {
    return x + "'"
  }

  public func freshen(x: Name) -> Name {
    if self.contains(x) {
      return self.freshen(x: nextName(x: x))
    }
    return x
  }
}
