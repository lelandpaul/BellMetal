import Foundation

public enum CoreSeven: Character, CaseIterable, CustomStringConvertible {
  case cambridge = "C"
  case yorkshire = "Y"
  case superlative = "S"
  case bristol = "B"
  case london = "L"
  case cornwall = "N"
  case lessness = "E"
  
  public var description: String { String(self.rawValue) }
  
  public var block: Block8 {
    return switch self {
    case .cambridge: "x38x14x1258x36x14x58x16x78,12"
    case .yorkshire: "x38x14x58x16x12x38x14x78,12"
    case .superlative: "x36x14x58x36x14x58x36x78,12"
    case .bristol: "x58x14.58x58.36.14x14.58x14x18,18"
    case .london: "38x38.14x12x38.14x14.58.16x16.58,12"
    case .cornwall: "x56x14x56x38x14x58x14x58,18"
    case .lessness: "x38x14x56x16x12x58x14x58,12"
    }
  }
}

public enum Call: CaseIterable, CustomStringConvertible {
  case start // special: only used to indicate the start of the search
  case plain, bob, single
  
  public var description: String {
    switch self {
    case .start: "S"
    case .plain: "p"
    case .bob: "b"
    case .single: "s"
    }
  }
  
  public var priority: Int {
    switch self {
    case .start: 0
    case .plain: 0
    case .bob: 1
    case .single: 2
    }
  }
  
  public static func fromString(_ string: String) -> Call {
    switch string {
    case "p": .plain
    case "b": .bob
    case "s": .single
    default: fatalError("encountered a call we couldn't parse")
    }
  }
  
  public func callAsFunction(_ method: CoreSeven) -> Block8 {
    let idx = method.block.pn.firstIndex(of: ",") ?? method.block.pn.endIndex
    return switch self {
    case .start: method.block
    case .plain: method.block
    case .bob: Block8(pn: method.block.pn[...idx] + "14")
    case .single: Block(pn: method.block.pn[...idx] + "1234")
    }
  }
}

public struct CSLead: Equatable, Hashable, CustomStringConvertible {
  let method: CoreSeven
  let lead: Row8
  
  init(method: CoreSeven, lead: Row8) {
    self.method = method
    self.lead = lead
  }
  
  init?(_ string: String) {
    guard string.count == 9,
          let method = CoreSeven(rawValue: string.first ?? "X"),
          let row = try? Row8(String(string.dropFirst())),
          row.isLeadHead,
          row.isTenorsTogether ?? false
    else { return nil }
    self.method = method
    self.lead = row
  }
  
  public var description: String {
    "\(method)\(lead)"
  }
  
  internal var rows: RowBlock8 {
    method.block.evaluate(at: lead)
  }
}

public struct CSLeadClass: Hashable, CustomStringConvertible {
  
  let method: CoreSeven
  let five: UInt8
  let six: UInt8
  let seven: UInt8
  let eight: UInt8
  let inCourse: Bool
  
  public var description: String {
    "\(method.rawValue)\(five)\(six)\(seven)\(eight)\(inCourse ? "i" : "o")"
  }
  
  
  public func overlap(_ other: CSLeadClass) -> Bool {
    guard self.method == other.method else { return false }
    return self.five == other.five || self.six == other.six || self.seven == other.seven || self.eight == other.eight
  }
  
  static let inCourseOrders: Set<Array<Bell>> = [
    [.b2, .b3, .b4],
    [.b3, .b4, .b2],
    [.b4, .b2, .b3]
  ]
  
  private static func getParity(_ row: Row8) -> Bool {
    let lbOrder = [.b2, .b3, .b4].sorted { a, b in
      row.position(of: a) < row.position(of: b)
    }
    return Self.inCourseOrders.contains(lbOrder)
  }
  
  init(method: CoreSeven, five: UInt8, six: UInt8, seven: UInt8, eight: UInt8, inCourse: Bool) {
    self.method = method
    self.five = five
    self.six = six
    self.seven = seven
    self.eight = eight
    self.inCourse = inCourse
  }
  
  init(_ lead: Row8, method: CoreSeven) {
    self.method = method
    self.five = UInt8(lead.position(of: .b5))
    self.six = UInt8(lead.position(of: .b6))
    self.seven = UInt8(lead.position(of: .b7))
    self.eight = UInt8(lead.position(of: .b8))
    self.inCourse = Self.getParity(lead)
  }
  
  init(_ lead: CSLead) {
    self.init(lead.lead, method: lead.method)
  }
  
  init?(_ string: String) {
    let characters = Array(string).map { String($0) }
    guard string.count == 6,
          let method = CoreSeven(rawValue: string.first ?? "X"),
          let five = UInt8(characters[1]),
          let six = UInt8(characters[2]),
          let seven = UInt8(characters[3]),
          let eight = UInt8(characters[4])
    else { return nil }
    self.method = method
    self.five = five
    self.six = six
    self.seven = seven
    self.eight = eight
    self.inCourse = characters[5] == "i"
  }
  
  init?(csleadString: String) {
    guard let cslead = CSLead(csleadString) else { return nil }
    self.init(cslead.lead, method: cslead.method)
  }
}

extension CSLeadClass: Equatable {
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs.inCourse == rhs.inCourse
    && lhs.five == rhs.five
    && lhs.six == rhs.six
    && lhs.seven == rhs.seven
    && lhs.eight == rhs.eight
    && lhs.method == rhs.method
  }
}

extension CSLeadClass {
  private var mask: Mask8 {
    var characters = ["1"] + Array(repeating: "x", count: 7)
    characters[Int(self.five)-1] = "5"
    characters[Int(self.six)-1] = "6"
    characters[Int(self.seven)-1] = "7"
    characters[Int(self.eight)-1] = "8"
    return Mask8(characters.joined())
  }
  
  public var rows: [Row8] {
    RowGenerator(matching: self.mask).filter {
      Self.getParity($0) == self.inCourse
    }
  }
}

