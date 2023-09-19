//
//  BaseTestCase.swift
//  Currency ConversionTests
//
//  Created by Akash Kahalkar on 13/06/22.
//

import Foundation
import XCTest
import CoreData
@testable import Currency_Conversion

class TestBase: XCTestCase {
    
    private var context = DataController.shared.container.viewContext

    override func setUpWithError() throws {
    }
    
    @MainActor
    override func tearDownWithError() throws {
    }
    
    func getConversionDataSource() -> ConversionDataSource? {
        
        if let crm = NSEntityDescription.insertNewObject(
            forEntityName: "ConversionRateMapping",
            into: context) as? ConversionRateMapping {
                        
            crm.base = "BSE"
            crm.disclaimer = ""
            crm.license = ""
            crm.timestamp = 161234
            crm.addToMapping(getConversionRate(base: "TST", amount: 2.0))
            crm.addToMapping(getConversionRate(base: "BSE", amount: 1.0))
            let countryCodeMapping = [
                getCountryCodeMapping(base: "BSE", countryName: "Base"),
                getCountryCodeMapping(base: "TST", countryName: "TEST")
            ]
            return ConversionDataSource(countryCodeMapping: countryCodeMapping,
                                        conversionRateMapping: crm)
        }
        
        return nil
        
    }
    
    func getCountryCodeMapping(base: String, countryName: String) -> ContryCodeMapping {
        
        if let c = NSEntityDescription.insertNewObject(
            forEntityName: "ContryCodeMapping",
            into: context) as? ContryCodeMapping {
            c.countryCode = base
            c.countryName = countryName
            return c
        }
        return ContryCodeMapping()
    }
    
    func getConversionRate(base: String, amount: Double) -> ConversionRates {

        if let cr = NSEntityDescription.insertNewObject(
            forEntityName: "ConversionRates",
            into: context) as? ConversionRates {
            cr.countryCode = base
            cr.conversionRate = amount
            return cr
        }
        return ConversionRates()
        
    }
}
