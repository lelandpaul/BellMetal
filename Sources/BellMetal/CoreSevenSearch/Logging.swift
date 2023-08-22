import Foundation

@available(macOS 10.15.0, *)
actor CSLogging {
  private var queue: [String] = []
  private let file: FileHandle
  
  init(filePath: String) {
    let url = URL(fileURLWithPath: filePath)
    self.file = try! FileHandle(forWritingTo: url)
    self.file.seekToEndOfFile() // moving pointer to the end
  }
  
  deinit {
    try! self.file.close()
  }
  
  public func callAsFunction(_ message: String) async {
    self.queue.append(message + "\n")
    Task.detached(operation: self.write)
  }
  
  @Sendable
  public func write() async {
    let messageToWrite = self.queue.remove(at: 0)
    self.file.write(messageToWrite.data(using: .utf8)!) // adding content
  }
  
}
