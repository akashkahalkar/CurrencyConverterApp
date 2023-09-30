//
//  TestConversionGridViewModel.swift
//  Currency ConversionTests
//
//  Created by Akash Kahalkar on 13/06/22.
//

import XCTest
@testable import Currency_Conversion

class TestCurrencyGridViewModel: TestBase {
    
    private var sut: ConversionGridViewModel?
    
    override func setUp() {
        if let ds = getConversionDataSource() {
            sut = ConversionGridViewModel(base: "TST", dataSource: ds, amount: 2)
        }
        
    }
    
    override func tearDown() {
        sut = nil
    }
    
    func testGetConversionAmount() {
        XCTAssertEqual(sut?.getConversionAmount(for: "BSE", amount: 2), "1.00")
    }
    
}
