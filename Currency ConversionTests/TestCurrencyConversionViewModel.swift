//
//  TestCurrencyConversionViewModel.swift
//  Currency ConversionTests
//
//  Created by Akash Kahalkar on 11/06/22.
//

import XCTest
@testable import Currency_Conversion

class TestCurrencyConversionViewModel: XCTestCase {
    
    private var sut: CurrencyConversionViewModel?
    
    override func setUpWithError() throws {
        sut = CurrencyConversionViewModel(appId: "TEST")
    }
    
    override func tearDownWithError() throws {
        sut = nil
    }
    
    func testAmountValidationEmptyValue() {
        XCTAssertNil(sut?.parseAmount("").amount)
        XCTAssertNotNil(sut?.parseAmount("").error)
    }
    
    func testAmountValidationValidAmount() {
        XCTAssertNotNil(sut?.parseAmount("123").amount)
        XCTAssertNotNil(sut?.parseAmount("123").error)
    }
    
    @MainActor
    func testAmountValidationValidDecimalAmount() {
        XCTAssertNotNil(sut?.parseAmount("123.0").amount)
        XCTAssertNotNil(sut?.parseAmount("123.0").error)
    }
    
    @MainActor
    func testAmountValidationInValidInput() {
        XCTAssertNil(sut?.parseAmount("ABCD").amount)
        XCTAssertNotNil(sut?.parseAmount("ABCD").error)
    }
}
