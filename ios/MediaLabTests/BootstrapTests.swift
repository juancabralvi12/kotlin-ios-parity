@preconcurrency import XCTest

@MainActor
final class BootstrapTests: XCTestCase {
    func testTestTargetRuns() {
        XCTAssertTrue(true)
    }
}
