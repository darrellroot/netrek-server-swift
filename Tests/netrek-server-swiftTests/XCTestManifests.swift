import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(netrek_server_swiftTests.allTests),
    ]
}
#endif
