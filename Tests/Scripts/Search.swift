import XCTest
@testable import BellMetal

final class SearchTest: XCTestCase {
  
  func testLoggerWorks() async {
    let log = CSLogging(filePath: "/Users/lelandpaul/Desktop/logtest.txt")
    await withTaskGroup(of: Void.self) { taskGroup in
      (1...10).forEach { i in
        taskGroup.addTask {
          await log("Task \(i) reporting in!")
        }
      }
    }
  }
  
  func testDoTheSearch() async throws {
    let log = CSLogging(filePath: "/Users/lelandpaul/Desktop/search.txt")
    await withTaskGroup(of: Void.self) { taskGroup in
      for method in CoreSeven.allCases {
        let search = SearchState(startingWith: method, logger: log)
        taskGroup.addTask {
          await search.run()
        }
      }
    }
  }
}
