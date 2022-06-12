//
//  ConversionGridViewModel.swift
//  Currency Conversion
//
//  Created by Akash Kahalkar on 11/06/22.
//

import Foundation
import SwiftUI


class ConversionGridViewModel: ObservableObject {
    
    @Published private var base: String
    private var dataSource: ConversionDataSource
    @Published var amount: Double = 0
    
    init(base: String, dataSource: ConversionDataSource, amount: Double) {
        self.base = base
        self.dataSource = dataSource
        self.amount = amount
    }
    
    func getCountryName(for code: String) -> String {
        return dataSource.getcountryName(code: code)
    }
    
    func getColor(for code: String) -> Color {
        let baseRate = dataSource.getRateFor(countryCode: base)
        let rateForGiveCountry = dataSource.getRateFor(countryCode: code)
        return dataSource.getColor(currentCountryRate: rateForGiveCountry,
                                   baseRate: baseRate, opacity: 0.1)
    }
    
    func getConversionAmount(for countryCode: String, amount: Double) -> String {
        var convertedAmount: Double
        let rateForBase = dataSource.getRateFor(countryCode: base)
        let rateForCurrentCountry = dataSource.getRateFor(countryCode: countryCode)
        if rateForBase != 1 && rateForBase != 0 {
            convertedAmount = (rateForCurrentCountry/rateForBase) * amount
        } else {
            convertedAmount = dataSource.getRateFor(countryCode: countryCode) * amount
        }
        
        return String(format: "%.3f", convertedAmount)
    }
    
    func getBase() -> String {
        return base
    }
    
    func getCountryCodes() -> [String] {
        print(dataSource.getCountryCodes())
        return dataSource.getCountryCodes()
    }
}
