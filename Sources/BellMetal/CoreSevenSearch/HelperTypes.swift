import Foundation


/// One step in the composition — a call leading to the next lead
struct SearchStep: CustomStringConvertible, Hashable {
  let call: Call
  let nextLead: CSLeadClass
  
  public var description: String {
    let callSymbol = switch call {
    case .start: ""
    case .plain: ""
    case .bob: "-"
    case .single: "s"
    }
    return "\(callSymbol)\(nextLead.description)"
  }
}

extension Set {
  public mutating func popRandom() -> Element? {
    guard let element = self.randomElement() else { return nil }
    self.remove(element)
    return element
  }
}

public struct ATWTracker {
  private var dict: [CoreSeven : [Int]] = {
    var dict = [CoreSeven : [Int]]()
    for method in CoreSeven.allCases {
      dict[method] = Array(repeating: 0, count: 7)
    }
    return dict
  }()
  
  public subscript(index: CoreSeven) -> [Int] {
    self.dict[index]!
  }
  
  public mutating func add(_ lead: CSLeadClass) {
    dict[lead.method]![lead.five] += 1
    dict[lead.method]![lead.six] += 1
    dict[lead.method]![lead.seven] += 1
    dict[lead.method]![lead.eight] += 1
  }
  
  public mutating func subtract(_ lead: CSLeadClass) {
    dict[lead.method]![lead.five] -= 1
    dict[lead.method]![lead.six] -= 1
    dict[lead.method]![lead.seven] -= 1
    dict[lead.method]![lead.eight] -= 1
  }
  
  public var isAtw: Bool {
    dict.allSatisfy { _, bells in
      bells.allSatisfy { $0 > 0 }
    }
  }
  
  public var isWithinLength: Bool {
    dict.allSatisfy { _, bells in
      bells.allSatisfy { $0 <= 5 }
    }
  }
  
  public func isAtwAgainst(_ other: ATWTracker) -> Bool {
    self.dict.allSatisfy { method, bells in
      let otherBells = other[method]
      return zip(bells, otherBells).allSatisfy { $0 + $1 > 0 }
    }
  }
  
  private func isUnique(method: CoreSeven, placebell: UInt8) -> Int {
    dict[method]![placebell] == 0 ? 1 : 0
  }
  
  public func effectiveness(of lead: CSLeadClass) -> Int {
    isUnique(method: lead.method, placebell: lead.five)
    + isUnique(method: lead.method, placebell: lead.six)
    + isUnique(method: lead.method, placebell: lead.seven)
    + isUnique(method: lead.method, placebell: lead.eight)
  }
}

extension Array where Element == Int {
  subscript(index: UInt8) -> Element {
    get {
      self[Int(index)-2]
    }
    set {
      self[Int(index)-2] = Swift.max(newValue, 0)
    }
  }
}
