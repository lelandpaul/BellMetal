import Foundation
import XCTest
@testable import BellMetal

final class GenerateAdjacency: XCTestCase {
  
  func testCalls() throws {
    let p = Call.plain(.bristol)
    let b = Call.bob(.bristol)
    let s = Call.single(.bristol)
    XCTAssertEqual(p, CoreSeven.bristol.block)
    XCTAssertEqual(b, Block8(pn: "x58x14.58x58.36.14x14.58x14x18,14"))
    XCTAssertEqual(s, Block8(pn: "x58x14.58x58.36.14x14.58x14x18,1234"))
  }
  
  private func getUsefulClasses() throws -> [CSLeadClass] {
    let savedString = try String(contentsOfFile: "/Users/lelandpaul/Desktop/coreSevenFalseness_byClass.txt")
    let unparsedDict = try JSONDecoder().decode([String : [String]].self, from: savedString.data(using: .utf8)!)
    var results = [CSLeadClass]()
    for (key, _) in unparsedDict {
      guard let csleadclass = CSLeadClass(key)
      else { fatalError("found something we couldn't parse") }
      results.append(csleadclass)
    }
    return results
  }
  
  func testUsefulClasses() throws {
    let classes = try getUsefulClasses()
    print(classes.count) // 1953 — so 7 were eliminated as "internally" false
  }
  
  func testConfirmBobsReallyWorkOnClasses() throws {
    let classes = try getUsefulClasses()
    for csclass in classes {
      let nextLeadheads = csclass.rows.map {
        $0 * Call.bob(csclass.method)
      }
      var nextClasses = Set<CSLeadClass>()
      for lh in nextLeadheads {
        for method in CoreSeven.allCases {
          nextClasses.insert(CSLeadClass(lh, method: method))
        }
      }
      guard nextClasses.count == 7 else {
        fatalError("oops")
      }
    }
  }
  
  private func nextLeadHeads(_ csclass: CSLeadClass, _ call: Call) -> [CSLeadClass] {
    let nextLeadhead = csclass.rows.map {
      $0 * call(csclass.method)
    }.first!
    var results = [CSLeadClass]()
    for method in CoreSeven.allCases {
      results.append(CSLeadClass(nextLeadhead, method: method))
    }
    return results
  }
  
  func testGenerateAdjacency() async throws {
    let classes = Set(try getUsefulClasses())
    
    let adjacency = await withTaskGroup(
      of: (String, [String: [String]]).self,
      returning: Dictionary<String, Dictionary<String, Array<String>>>.self) { taskGroup in
      for csclass in classes {
        taskGroup.addTask {
          var smallResult = [String: [String]]()
          for call in Call.allCases {
            let adjacent = self.nextLeadHeads(csclass, call)
            smallResult[call.description] = adjacent
              .filter { classes.contains($0) }.map { $0.description }
          }
          return (csclass.description, smallResult)
        }
      }
      
      var bigResult = Dictionary<String, Dictionary<String, Array<String>>>()
      for await (key, value) in taskGroup {
        bigResult[key] = value
      }
      return bigResult
    }
    let json = try JSONSerialization.data(withJSONObject: adjacency, options: .prettyPrinted)
    let url = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
    try json.write(to: url!.appendingPathComponent("coreSevenAdjacency.txt"))
  }
}
