import XCTest
import Foundation
@testable import BellMetal
import OSLog

final class GenerateFalsenessTests: XCTestCase {
  
  var leadheadFinders: [Int : [CoreSeven : [Row8]]] = {
    var results = [Int : [CoreSeven : [Row8]]]()
    for method in CoreSeven.allCases {
      for pos in 1...8 {
        if results[pos] == nil {
          results[pos] = [:]
        }
        results[pos]![method] = method.block.rowsWithTreble(at: pos).map { $0 ^ -1 }
      }
    }
    return results
  }()
  
  func tenorsTogetherLeads(containing row: Row8, of method: CoreSeven) -> [Row8] {
    let pos = row.position(of: .b1)
    return leadheadFinders[pos]![method]!.map {
      row * $0
    }.filter {
      $0.isTenorsTogether!
    }
  }
  
  func testFindingLeadheads() throws {
    let test = Major.rounds
    var results: [CoreSeven : [Row8]] = [:]
    for method in CoreSeven.allCases {
      results[method] = tenorsTogetherLeads(containing: test, of: method)
    }
    print(results)
  }
  
  func testFindAllFalseness() async throws {
    let finalResults = await withTaskGroup(of: Set<String>.self, returning: [String : Set<String>].self) { taskGroup in
      var results = [String : Set<String>]()
      for row in Major.rows {
        taskGroup.addTask {
          var leadsContainingRow = Set<String>()
          for method in CoreSeven.allCases {
            self.tenorsTogetherLeads(containing: row, of: method).forEach { lead in
              leadsContainingRow.insert(CSLead(method: method, lead: lead).description)
            }
          }
          return leadsContainingRow
        }
      }
      
      for await result in taskGroup {
        for lead in result {
          let resultWithoutHead = result.subtracting(Set([lead]))
          if results[lead] == nil {
            results[lead] = resultWithoutHead
          } else {
            results[lead]?.formUnion(resultWithoutHead)
          }
        }
      }
      return results
    }
    let arrayifiedResults: [String : [String]] = {
      var results: [String : [String]] = [:]
      for (key, value) in finalResults {
        results[key] = Array(value)
      }
      return results
    }()
    let json = try JSONSerialization.data(withJSONObject: arrayifiedResults, options: .prettyPrinted)
    let url = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
    try json.write(to: url!.appendingPathComponent("coreSevenFalseness.txt"))
  }
  
  func testTruth() throws {
    let pb4: Block4 = "x14x14,12"
    let lead1 = pb4.evaluate(at: Row4.rounds())
    let lead2 = pb4.evaluate(at: lead1.last!)
    let lead2Backwards = pb4.evaluate(at: lead2.rows[lead2.count-2])
    XCTAssertTrue(lead1.isTrue(against: lead2))
    XCTAssertTrue(lead2.isTrue(against: lead1))
    XCTAssertFalse(lead2.isTrue(against: lead2Backwards))
    XCTAssertFalse(lead1.isTrue(against: lead2Backwards))
  }
  
  func testOtherTruth() throws {
    let leadhead: Row8 = "13748625"
    let superlative = CSLead(method: .superlative, lead: leadhead)
    let london = CSLead(method: .london, lead: leadhead)
    XCTAssertTrue(superlative.rows.isTrue(against: london.rows))
  }
  
  func testConfirmFalsenessResults() async throws {
    let savedString = try String(contentsOfFile: "/Users/lelandpaul/Desktop/coreSevenFalseness.txt")
    let unparsedDict = try JSONDecoder().decode([String : [String]].self, from: savedString.data(using: .utf8)!)
    let finalResults = await withTaskGroup(of: Optional<(CSLead, CSLead)>.self, returning: Optional<(CSLead, CSLead)>.self) { taskGroup in
      for (key, value) in unparsedDict {
        let prime = CSLead(key)
        for block in value {
          let wasAdded = taskGroup.addTaskUnlessCancelled {
            guard let prime,
                  let second = CSLead(block),
                  !Task.isCancelled
            else { return Optional.none }
            if prime.rows.isTrue(against: second.rows) {
              return (prime, second)
            }
            return Optional.none
          }
          guard wasAdded else { break }
        }
      }
      for await result in taskGroup {
        if let nonNullResult = result {
          taskGroup.cancelAll()
          return nonNullResult
        } else {
          continue
        }
      }
      return Optional.none
    }
    XCTAssertTrue(finalResults == nil)
  }
  
  func testConfirmClassesWork() throws {
    let partends: [Row8] = ["12345678", "13425678", "14235678"]
    
    let base: Row8 = "13748625"
    let baseRotated = partends.map { $0 * base }
    let baseClasses = Set(baseRotated.map { CSLeadClass($0, method: .bristol)})
    XCTAssertEqual(1, baseClasses.count)
    
    let oBase: Row8 = "14738625"
    let oBaseRotated = partends.map { $0 * oBase }
    let oBaseClasses = Set(oBaseRotated.map { CSLeadClass($0, method: .bristol)})
    XCTAssertEqual(1, oBaseClasses.count)
    
    XCTAssertNotEqual(baseClasses, oBaseClasses)
  }
  
  func testCollapseFalsenessByClass() async throws {
    let savedString = try String(contentsOfFile: "/Users/lelandpaul/Desktop/coreSevenFalseness.txt")
    let unparsedDict = try JSONDecoder().decode([String : [String]].self, from: savedString.data(using: .utf8)!)
    let collapsedResults = await withTaskGroup(
      of: Optional<(CSLeadClass, Set<CSLeadClass>)>.self,
      returning: [String : [String]].self) { taskGroup in
        for (key, value) in unparsedDict {
          taskGroup.addTask {
            guard let headClass = CSLeadClass(csleadString: key) else { fatalError("couldn't parse headClass \(key)") }
            let secondariesParsed = value.compactMap {
              CSLeadClass(csleadString: $0)
            }
            let secondaries = Set(secondariesParsed)
            guard !secondaries.contains(headClass) else { return Optional.none }
            return (headClass, secondaries)
          }
        }
        
        var results = [String: [String]]()
        for await result in taskGroup {
          guard let (head, seconds) = result
          else { continue }
          results[head.description] = seconds.map { $0.description }
        }
        return results
      }
    
    let json = try JSONSerialization.data(withJSONObject: collapsedResults, options: .prettyPrinted)
    let url = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
    try json.write(to: url!.appendingPathComponent("coreSevenFalseness_byClass.txt"))
  }
}


