//
//  TestURLManager.swift
//  Currency ConversionTests
//
//  Created by Akash Kahalkar on 10/06/22.
//

import XCTest
@testable import Currency_Conversion

class TestURLManager: XCTestCase {
    
    private var sut: OERURLManager?
    
    override func setUp() {
        sut = OERURLManager("TEST")
    }

    override func tearDown() {
        sut = nil
    }
    
    func testGetLatestRateUrl() {
        XCTAssertNotNil(sut?.getLatestRateUrl())
        XCTAssertEqual(sut?.getLatestRateUrl()?.absoluteString,
                       "https://openexchangerates.org/api/latest.json?app_id=TEST&base=USD")
    }
    
    func testGetLatestRateUrlWithBase() {
        XCTAssertNotNil(sut?.getLatestRateUrl(base: "INR"))
        XCTAssertEqual(sut?.getLatestRateUrl(base: "INR")?.absoluteString,
                       "https://openexchangerates.org/api/latest.json?app_id=TEST&base=INR")
    }
    
    func testGetCurrencie() {
        XCTAssertNotNil(sut?.getCurrencies())
        XCTAssertEqual(sut?.getCurrencies()?.absoluteString,
                       "https://openexchangerates.org/api/currencies.json")
    }
}
