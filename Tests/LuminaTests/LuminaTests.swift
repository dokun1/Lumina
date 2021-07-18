//
//  LuminaTests.swift
//  LuminaTests
//
//  Created by David Okun on 4/21/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import XCTest
@testable import Lumina

class LuminaTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testLogging() {
        // Logging should happen at the specified level and at *higher* levels
        // e.g. if level is set to error, critical and error should be logged, but not warning, notice, etc.
        LuminaLogger.level = .error
        XCTAssertTrue(LuminaLogger.wouldLog(level: .critical))
        XCTAssertTrue(LuminaLogger.wouldLog(level: .error))
        XCTAssertFalse(LuminaLogger.wouldLog(level: .warning))
        XCTAssertFalse(LuminaLogger.wouldLog(level: .notice))
        XCTAssertFalse(LuminaLogger.wouldLog(level: .info))
        XCTAssertFalse(LuminaLogger.wouldLog(level: .debug))
        XCTAssertFalse(LuminaLogger.wouldLog(level: .trace))

        LuminaLogger.level = .info
        XCTAssertTrue(LuminaLogger.wouldLog(level: .critical))
        XCTAssertTrue(LuminaLogger.wouldLog(level: .error))
        XCTAssertTrue(LuminaLogger.wouldLog(level: .warning))
        XCTAssertTrue(LuminaLogger.wouldLog(level: .notice))
        XCTAssertTrue(LuminaLogger.wouldLog(level: .info))
        XCTAssertFalse(LuminaLogger.wouldLog(level: .debug))
        XCTAssertFalse(LuminaLogger.wouldLog(level: .trace))
    }

}
