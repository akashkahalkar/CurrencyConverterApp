//
//  ConversionDataSource.swift
//  Currency Conversion
//
//  Created by Akash Kahalkar on 12/06/22.
//

import Foundation
import SwiftUI

class ConversionDataSource {
    
    private var conversionMappings = [String: (countryName: String, conversionRate: Double)]()
    
    private var base: String
    private var timestamp: Double = 0
    private var license: String?
    private var disclaimer: String?
    
    init(countryCodeMapping: [ContryCodeMapping],
         conversionRateMapping: ConversionRateMapping?) {
        
        self.base = conversionRateMapping?.base ?? "USD"
        self.timestamp = conversionRateMapping?.timestamp ?? 0
        self.license = conversionRateMapping?.license
        self.disclaimer = conversionRateMapping?.disclaimer
        let countryNameMapping = loadCountryNameMapping(objects: countryCodeMapping)
        let conversionRateMapping = loadConversionRateMapping(object: conversionRateMapping)
        self.conversionMappings = loadMapping(countryNameMapping, conversionRateMapping)
    }
}

extension ConversionDataSource {
    // MARK: private function
    private func loadCountryNameMapping(objects: [ContryCodeMapping]) -> [String: String] {
        return mapToDictionary(countryNameArray: objects)
    }
    
    private func loadConversionRateMapping(object: ConversionRateMapping?) -> [String: Double] {
        guard let object = object else {
            return [:]
        }
        return mapToDictionary(conversionRateData: object)
    }
    
    private func loadMapping(
        _ countryNameMapping: [String: String],
        _ rateMapping: [String: Double]
    ) -> [String: (String, Double)] {
    
        var mergedDictionary = [String: (String, Double)]()
        for countryCode in Set(countryNameMapping.keys).intersection(rateMapping.keys) {
            // Get values from both dictionaries
            if let name = countryNameMapping[countryCode], let value = rateMapping[countryCode] {
                // Create a tuple and add it to the merged dictionary
                mergedDictionary[countryCode] = (name, value)
            }
        }
        return mergedDictionary
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
}

extension ConversionDataSource {
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
            conversionMappings[countryCode]?.conversionRate ?? 0
        }
        
        func getcountryName(code: String) -> String {
            conversionMappings[code]?.countryName ?? ""
        }
        
        func getCountryCodes() -> [String] {
            return conversionMappings.keys.compactMap{ $0 }
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
        
        func getLicenseURL() -> URL? {
            return URL(string: self.license ?? "")
        }
        
        func getDisclaimerURL() -> URL? {
            return URL(string: self.disclaimer ?? "")
        }
}
