//
//  testConversionDataSourceTEst.swift
//  Currency ConversionTests
//
//  Created by Akash Kahalkar on 12/06/22.
//

import Foundation
import XCTest
@testable import Currency_Conversion


class TestConversionDataSource: XCTest {
    
    private var sut: ConversionDataSource?
    
    override func setUpWithError() throws {
        
        let c = ContryCodeMapping()
        c.countryCode = "TST"
        c.countryName = "Test"
        
        let cr = ConversionRates()
        cr.countryCode = "TST"
        cr.conversionRate = 1.0
        
        let crm = ConversionRateMapping()
        crm.base = "TEST"
        crm.disclaimer = ""
        crm.license = ""
        crm.timestamp = 0
        crm.addToMapping(cr)
        
        sut = ConversionDataSource(countryCodeMapping: [c],
                                   conversionRateMapping: crm)
    }
    
    @MainActor
    override func tearDownWithError() throws {
        sut = nil
    }
    
    func testDummy() {
        XCTAssertEqual(sut?.getcountryName(code: "TST"), "Test")
    }
}
