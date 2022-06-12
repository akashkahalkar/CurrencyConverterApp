//
//  ConversionDataSource.swift
//  Currency Conversion
//
//  Created by Akash Kahalkar on 12/06/22.
//

import Foundation
import SwiftUI

class ConversionDataSource {
    
    private var countryNameMapping = [String: String]()
    private var conversionRateMapping = [String: Double]()
    private var base: String
    private var timestamp: Double = 0
    
    init(countryCodeMapping: [ContryCodeMapping],
                 conversionRateMapping: ConversionRateMapping?) {
        self.base = conversionRateMapping?.base ?? "USD"
        self.timestamp = conversionRateMapping?.timestamp ?? 0
        loadCountryNameMapping(objects: countryCodeMapping)
        loadConversionRateMapping(object: conversionRateMapping)
    }
    
    // MARK: private function
    private func loadCountryNameMapping(objects: [ContryCodeMapping]) {
        countryNameMapping = mapToDictionary(countryNameArray: objects)
    }
    
    private func loadConversionRateMapping(object: ConversionRateMapping?) {
        guard let object = object else {
            conversionRateMapping = [:]
            return
        }
        conversionRateMapping = mapToDictionary(conversionRateData: object)
    }
    
    private func mapToDictionary(conversionRateData: ConversionRateMapping) -> [String: Double] {
        var rateMapping: [String: Double] = [:]
        let conversionRates: [ConversionRates] = conversionRateData
            .mapping?
            .compactMap({$0 as? ConversionRates}) ?? []
        
        conversionRates.forEach { rate in
            if let countryCode = rate.countryCode {
                rateMapping[countryCode] = rate.conversionRate
            }
        }
        return rateMapping
    }
    private func mapToDictionary(countryNameArray: [ContryCodeMapping]) -> [String: String] {
        var map: [String: String] = [:]
        countryNameArray.forEach { ccm in
            if let code = ccm.countryCode {
                map[code] = ccm.countryName ?? ""
            }
        }
        return map
    }
    
    // MARK: public interfaces
    func getColor(currentCountryRate: Double, baseRate: Double, opacity: Double) -> Color {
        
        if baseRate < currentCountryRate {
            return Color.green.opacity(opacity)
        } else if baseRate > currentCountryRate {
            return Color.red.opacity(opacity)
        } else {
            return Color.blue.opacity(opacity)
        }
        
    }
    
    func getRateFor(countryCode: String) -> Double {
        guard let amount = conversionRateMapping[countryCode] else {
            return 0
        }
        return amount
    }
    
    func getcountryName(code: String) -> String {
        guard let amount = countryNameMapping[code] else {
            return "NA"
        }
        return String(amount)
    }
    
    func getCountryCodes() -> [String] {
        return countryNameMapping.keys.map({$0})
    }
    
    func getBase() -> String {
        return base
    }
    
    
    func getLastUpdateDate() -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = DateFormatter.Style.medium //Set time style
            dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
            dateFormatter.timeZone = .autoupdatingCurrent
            let localDate = dateFormatter.string(from: date)
        return localDate
    }
    
    func getLastFetchTimeStamp() -> Double {
        return timestamp
    }
    
    func getCurrentDateTimeStamp() -> Double {
        return Date().timeIntervalSince1970
    }
}
