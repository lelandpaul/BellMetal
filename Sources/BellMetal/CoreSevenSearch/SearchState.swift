import Foundation

@available(macOS 10.15.0, *)
class SearchState {
  
  private let name: String
  private let roundsLeadClass: CSLeadClass
  private let log: CSLogging
  
  private var globalPossible: Set<CSLeadClass> = getUsefulClasses()
  private var searchSteps: [SearchStep] = []
  private var adjacentPossible: [Array<SearchStep>] = []
  private var proximalFalseness: [Set<CSLeadClass>] = []
  
  private var possibleAtw = ATWTracker()
  private var actualAtw = ATWTracker()
  
  private var cycle: Int = 0
  private var maxDepth: Int = 0
  
  
  init(startingWith method: CoreSeven, logger: CSLogging) {
    self.name = "SearchState-\(method.description)"
    self.roundsLeadClass = CSLeadClass(
      method: method,
      five: 5,
      six: 6,
      seven: 7,
      eight: 8,
      inCourse: true
    )
    self.log = logger
    self.globalPossible.forEach { possibleAtw.add($0) }
    forward(SearchStep(call: .start, nextLead: roundsLeadClass))
  }
  
  private func isAdjacentToPartend(_ lead: CSLeadClass) -> Bool {
    guard let adjacent = adjacency[lead] else { return false }
    for step in adjacent {
      if step.nextLead == roundsLeadClass { return true }
    }
    return false
  }
  
  private func sort(lhs: SearchStep, rhs: SearchStep) -> Bool {
    // Deprioritize things adjacent to the partend... unless we're near the end
    let lhsAdjacent = isAdjacentToPartend(lhs.nextLead)
    let rhsAdjacent = isAdjacentToPartend(rhs.nextLead)
    if lhsAdjacent != rhsAdjacent {
      return searchSteps.count >= 33 ? lhsAdjacent : !lhsAdjacent
    }
    
    // Prioritize things that get us closer to ATW
    let lhsAtw = actualAtw.effectiveness(of: lhs.nextLead)
    let rhsAtw = actualAtw.effectiveness(of: rhs.nextLead)
    if lhsAtw != rhsAtw {
      return lhsAtw > rhsAtw
    }
    
    // Prioritize things that have less falseness
    let lhsFalseness = globalPossible.intersection(falseness[lhs.nextLead]!).count
    let rhsFalseness = globalPossible.intersection(falseness[rhs.nextLead]!).count
    if lhsFalseness != rhsFalseness {
      return lhsFalseness < rhsFalseness
    }
    
    // Prefer p < b s
    if lhs.call != rhs.call {
      return lhs.call.priority < rhs.call.priority
    }
    
    // idk sort alphabetically I guess
    return lhs.nextLead.description < rhs.nextLead.description
  }
  
  private func forward(_ step: SearchStep) {
    self.searchSteps.append(step)
    self.actualAtw.add(step.nextLead)
    self.globalPossible.remove(step.nextLead)
    self.possibleAtw.subtract(step.nextLead)
    let localFalseness = globalPossible.intersection(falseness[step.nextLead]!)
    globalPossible.subtract(localFalseness)
    proximalFalseness.append(localFalseness)
    adjacentPossible.append(adjacency[step.nextLead]!.sorted(by: sort(lhs:rhs:)).reversed())
  }
  
  private func backward() {
    _ = self.adjacentPossible.popLast()
    guard let lastStep = self.searchSteps.popLast() else { fatalError("something terrible happened while backtracking") }
    guard let lastFalseness = self.proximalFalseness.popLast() else { fatalError("something terrible happened while backtracking") }
    self.globalPossible.insert(lastStep.nextLead)
    self.globalPossible.formUnion(lastFalseness)
    self.actualAtw.subtract(lastStep.nextLead)
    self.possibleAtw.add(lastStep.nextLead)
  }
  
  /// Lead adjacency, loaded from file at initialization
  public let adjacency: [CSLeadClass : [SearchStep]] = {
    var results = [CSLeadClass : [SearchStep]]()
    do {
      let savedString = try String(contentsOfFile: "/Users/lelandpaul/Desktop/coreSevenAdjacency.txt")
      let unparsedDict = try JSONDecoder().decode([String: [String : [String]]].self, from: savedString.data(using: .utf8)!)
      for (head, calls) in unparsedDict {
        let headClass = CSLeadClass(head)!
        results[headClass] = []
        for (callString, outcomes) in calls {
          let call = Call.fromString(callString)
          for outcome in outcomes {
            let step = SearchStep(call: call, nextLead: CSLeadClass(outcome)!)
            results[headClass]?.append(step)
          }
        }
      }
    } catch {
      fatalError("Couldn't parse the adjacency file")
    }
    return results
  }()
  
  
  public let falseness: [CSLeadClass : Set<CSLeadClass>] = {
    var results = [CSLeadClass : Set<CSLeadClass>]()
    do {
      let savedString = try String(contentsOfFile: "/Users/lelandpaul/Desktop/coreSevenFalseness_byClass.txt")
      let unparsedDict = try JSONDecoder().decode([String: [String]].self, from: savedString.data(using: .utf8)!)
      for (head, values) in unparsedDict {
        guard let headClass = CSLeadClass(head)
        else { fatalError("Encountered something unparsable in falseness") }
        var secondaries = Set<CSLeadClass>()
        for secondary in values {
        guard let secondaryClass = CSLeadClass(secondary)
        else { fatalError("Encountered something unparsable in falseness") }
          secondaries.insert(secondaryClass)
        }
        results[headClass] = secondaries
      }
    } catch {
      fatalError("Couldn't parse the falseness file")
    }
    return results
  }()
  
  /// Get only those classes that are not self-false
  /// - Returns: set of non-self-false lead classes
  private static func getUsefulClasses() -> Set<CSLeadClass> {
    do {
      let savedString = try String(contentsOfFile: "/Users/lelandpaul/Desktop/coreSevenFalseness_byClass.txt")
      let unparsedDict = try JSONDecoder().decode([String : [String]].self, from: savedString.data(using: .utf8)!)
      var results = [CSLeadClass]()
      for (key, _) in unparsedDict {
        guard let csleadclass = CSLeadClass(key)
        else { fatalError("found something we couldn't parse") }
        results.append(csleadclass)
      }
      return Set(results)
    } catch {
      fatalError("Error getting useful classes")
    }
  }
}



@available(macOS 10.15.0, *)
extension SearchState {
  
  public func run() async {
    while true {
      self.cycle += 1
      self.maxDepth = max(self.maxDepth, self.searchSteps.count)
      if cycle.isMultiple(of: 100000) {
        await log("\(name): \(cycle) cycle, maxDepth is \(maxDepth)")
      }
      // Enter loop
      // Check win condition
      if self.win {
        await log("RESULT: \(self.searchSteps)")
        backward()
        continue
      }
      // Check lose condition
      if self.lose {
        continue
      }
      // Check too long
      if self.searchSteps.count == 54 {
        backward()
        continue
      }
      // Try to get next step
      guard let nextStep = self.adjacentPossible[adjacentPossible.indices.last!].popLast(), // there is something in the possible
            self.possibleAtw.isAtwAgainst(actualAtw), // ATW is still possible
            self.actualAtw.isWithinLength // ATW is still possible
      else {
        // nothing doing
        backward()
        continue
      }
      // - Got it: go forward
      if self.globalPossible.contains(nextStep.nextLead) { // our next lead isn't already false
        forward(nextStep)
      }
    }
  }
  
  private var adjacentPossibleLeads: Set<CSLeadClass> {
    Set(self.adjacentPossible.last?.map({$0.nextLead}) ?? [])
  }
  
  private var win: Bool {
    return self.searchSteps.count >= 53
    && self.adjacentPossibleLeads.contains(self.roundsLeadClass)
    && self.actualAtw.isAtw
  }
  
  private var lose: Bool {
    return self.searchSteps.count == 1
    && self.adjacentPossibleLeads.isEmpty
  }
}
