//
//  LatestConversionRate.swift
//  Currency Conversion
//
//  Created by Akash Kahalkar on 10/06/22.
//

import Foundation


struct ConversionRateResponse: Codable {
    let disclaimer: String
    let license: String
    let base: String
    let timestamp: Double
    let rates: [String: Double]
}

typealias CurrenciesResponse = [String: String]
