//
//  testConversionDataSourceTEst.swift
//  Currency ConversionTests
//
//  Created by Akash Kahalkar on 12/06/22.
//

import Foundation
import XCTest
@testable import Currency_Conversion
import SwiftUI


class TestConversionDataSource: TestBase {
    
    private var sut: ConversionDataSource?
    
    override func setUpWithError() throws {
        sut = getConversionDataSource()
    }
    
    @MainActor
    override func tearDownWithError() throws {
        sut = nil
    }
    
    func testGetColor() {
        XCTAssertEqual(sut?.getColor(currentCountryRate: 1, baseRate: 2, opacity: 1), Color.red.opacity(1))
        XCTAssertEqual(sut?.getColor(currentCountryRate: 2, baseRate: 1, opacity: 1), Color.green.opacity(1))
        XCTAssertEqual(sut?.getColor(currentCountryRate: 1, baseRate: 1, opacity: 1), Color.blue.opacity(1))
    }
    
    func testGetRateFor() {
        XCTAssertEqual(sut?.getRateFor(countryCode: "TST"), 2.0)
        XCTAssertEqual(sut?.getRateFor(countryCode: "AFK"), 0)
    }
    
    func testGetcountryName() {
        XCTAssertEqual(sut?.getcountryName(code: "TST"), "TEST")
        XCTAssertEqual(sut?.getcountryName(code: "AFK"), "NA")
    }
    
    func testGetCountryCodes() {
        XCTAssertEqual(sut?.getCountryCodes(), ["BSE", "TST"])
    }
    
    func testGetBase() {
        XCTAssertEqual(sut?.getBase(), "BSE")
    }
}
