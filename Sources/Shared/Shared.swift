import Foundation

public typealias Name = String

extension Dictionary {
  public func extend(name: Key, value: Value) -> [Key: Value] {
    var result = self
    result[name] = value
    return result
  }
}

extension Array {
  public init(head: Element, rest: [Element]) {
    self.init()
    self.append(head)
    self.append(contentsOf: rest)
  }
}

extension [Name] {
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

extension [(Name, Int)] {
  public func lookup(_ name: Name) -> Int? {
    return first(where: { (n, _) in n == name }).map { (_, i) in i }
  }
}
