import Foundation

public protocol StageProtocol {
  static var n: Int { get }
  static var description: String { get }
  static var musicScheme: MusicScheme<Self> { get set }
  static var pbLeadheads: Set<Row<Self>> { get }
}

extension StageProtocol {
  public static var bells: [Bell] {
    Array(1...n).map { Bell(rawValue: $0)! }
  }
  public static var tenor: Bell {
    Bell(rawValue: n)! // Safe: stage ns are known in advance
  }
  public static var nearTenor: Bell {
    Bell(rawValue: n-1)! // Safe: stage ns are known in advance
  }
}

public enum Singles: StageProtocol {
  public static let n: Int = 3
  public static let description: String = "Singles"
  public static var musicScheme = MusicScheme<Self>.standard
  public static let pbLeadheads: Set<Row<Singles>> = []
}

public enum Minimus: StageProtocol {
  public static let n: Int = 4
  public static let description: String = "Minimus"
  public static var musicScheme = MusicScheme<Self>.standard
  public static let pbLeadheads: Set<Row<Minimus>> = [
    "1342", "1423", "1234"
  ]
}

public enum Doubles: StageProtocol {
  public static let n: Int = 5
  public static let description: String = "Doubles"
  public static var musicScheme = MusicScheme<Self>.standard
  public static let pbLeadheads: Set<Row<Doubles>> = [
    "13524", "15432", "14253", "12345"
  ]
}

public enum Minor: StageProtocol {
  public static let n: Int = 6
  public static let description: String = "Minor"
  public static var musicScheme = MusicScheme<Self>.standard
  public static let pbLeadheads: Set<Row<Minor>> = [
    "135264", "156342", "164523", "142635", "123456"
  ]
}

public enum Triples: StageProtocol {
  public static let n: Int = 7
  public static let description: String = "Triples"
  public static var musicScheme = MusicScheme<Self>.standard
  public static let pbLeadheads: Set<Row<Triples>> = [
    "1352746", "1573624", "1765432", "1647253", "1426375", "1234567"
  ]
}

public enum Major: StageProtocol {
  public static let n: Int = 8
  public static let description: String = "Major"
  public static var musicScheme = MusicScheme<Self>.standard
  public static let pbLeadheads: Set<Row<Major>> = [
    "13527486",
    "15738264",
    "17856342",
    "18674523",
    "16482735",
    "14263857",
    "12345678",
  ]
}

public enum Caters: StageProtocol {
  public static let n: Int = 9
  public static let description: String = "Caters"
  public static var musicScheme = MusicScheme<Self>.standard
  public static let pbLeadheads: Set<Row<Caters>> = [
    "135274968",
    "157392846",
    "179583624",
    "198765432",
    "186947253",
    "164829375",
    "142638597",
    "123456789",
  ]
}

public enum Royal: StageProtocol {
  public static let n: Int = 10
  public static let description: String = "Royal"
  public static var musicScheme = MusicScheme<Self>.standard
  public static let pbLeadheads: Set<Row<Royal>> = [
    "1352749608",
    "1573920486",
    "1795038264",
    "1907856342",
    "1089674523",
    "1860492735",
    "1648203957",
    "1426385079",
    "1234567890",
  ]
}

public enum Cinques: StageProtocol {
  public static let n: Int = 11
  public static let description: String = "Cinques"
  public static var musicScheme = MusicScheme<Self>.standard
  public static let pbLeadheads: Set<Row<Cinques>> = [
    "13527496E80",
    "157392E4068",
    "1795E302846",
    "19E70583624",
    "1E098765432",
    "108E6947253",
    "18604E29375",
    "1648203E597",
    "142638507E9",
    "1234567890E",
  ]
}

public enum Maximus: StageProtocol {
  public static let n: Int = 12
  public static let description: String = "Maximus"
  public static var musicScheme = MusicScheme<Self>.standard
  public static let pbLeadheads: Set<Row<Maximus>> = [
    "13527496E8T0",
    "157392E4T608",
    "1795E3T20486",
    "19E7T5038264",
    "1ET907856342",
    "1T0E89674523",
    "108T6E492735",
    "18604T2E3957",
    "1648203T5E79",
    "142638507T9E",
    "1234567890ET",
  ]
}

public enum Thirteen: StageProtocol {
  public static let n: Int = 13
  public static let description: String = "Thirteen"
  public static var musicScheme = MusicScheme<Self>.standard
  public static let pbLeadheads: Set<Row<Thirteen>> = [
    "13527496E8A0T",
    "157392E4A6T80",
    "1795E3A2T4068",
    "19E7A5T302846",
    "1EA9T70583624",
    "1ATE098765432",
    "1T0A8E6947253",
    "108T6A4E29375",
    "18604T2A3E597",
    "1648203T5A7E9",
    "142638507T9AE",
    "1234567890ETA",
  ]
}

public enum Fourteen: StageProtocol {
  public static let n: Int = 14
  public static let description: String = "Fourteen"
  public static var musicScheme = MusicScheme<Self>.standard
  public static let pbLeadheads: Set<Row<Fourteen>> = [
    "13527496E8A0BT",
    "157392E4A6B8T0",
    "1795E3A2B4T608",
    "19E7A5B3T20486",
    "1EA9B7T5038264",
    "1ABET907856342",
    "1BTA0E89674523",
    "1T0B8A6E492735",
    "108T6B4A2E3957",
    "18604T2B3A5E79",
    "1648203T5B7A9E",
    "142638507T9BEA",
    "1234567890ETAB",
  ]
}

public enum Fifteen: StageProtocol {
  public static let n: Int = 15
  public static let description: String = "Fifteen"
  public static var musicScheme = MusicScheme<Self>.standard
  public static let pbLeadheads: Set<Row<Fifteen>> = [
    "13527496E8A0CTB",
    "157392E4A6C8B0T",
    "1795E3A2C4B6T80",
    "19E7A5C3B2T4068",
    "1EA9C7B5T302846",
    "1ACEB9T70583624",
    "1CBATE098765432",
    "1BTC0A8E6947253",
    "1T0B8C6A4E29375",
    "108T6B4C2A3E597",
    "18604T2B3C5A7E9",
    "1648203T5B7C9AE",
    "142638507T9BECA",
    "1234567890ETABC",
  ]
}

public enum Sixteen: StageProtocol {
  public static let n: Int = 16
  public static let description: String = "Sixteen"
  public static var musicScheme = MusicScheme<Self>.standard
  public static let pbLeadheads: Set<Row<Sixteen>> = [
    "13527496E8A0CTDB",
    "157392E4A6C8D0BT",
    "1795E3A2C4D6B8T0",
    "19E7A5C3D2B4T608",
    "1EA9C7D5B3T20486",
    "1ACED9B7T5038264",
    "1CDABET907856342",
    "1DBCTA0E89674523",
    "1BTD0C8A6E492735",
    "1T0B8D6C4A2E3957",
    "108T6B4D2C3A5E79",
    "18604T2B3D5C7A9E",
    "1648203T5B7D9CEA",
    "142638507T9BEDAC",
    "1234567890ETABCD",
  ]
}
