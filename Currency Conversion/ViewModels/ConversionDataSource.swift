//
//  ConversionDataSource.swift
//  Currency Conversion
//
//  Created by Akash Kahalkar on 12/06/22.
//

import Foundation
import SwiftUI

struct CountryListPickerData {
    var countryCode: String
    var countryName: String
}

class ConversionDataSource {
    
    private var conversionMappings = [String: (countryName: String, conversionRate: Double)]()
    private var base: String
    private var timestamp: Double = 0
    private var license: String?
    private var disclaimer: String?
        
    init(
        mappings: [String: (String, Double)], 
        base: String,
        timestamp: Double,
        license: String,
        disclaimer: String
    ) {
        
        self.base = base
        self.timestamp = timestamp
        self.license = license
        self.disclaimer = disclaimer
        self.conversionMappings = mappings
    }
    
    static let empty = ConversionDataSource(mappings: [:], base: "", timestamp: 0, license: "", disclaimer: "")
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
        
        func getCountryCodes() -> [CountryListPickerData] {
            
            let keys = Array(conversionMappings.keys)
            var countryPickerList = [CountryListPickerData]()
            keys.forEach { key in
                if let name = conversionMappings[key]?.countryName {
                    countryPickerList.append(CountryListPickerData(countryCode: key, countryName: name))
                }
            }
            return countryPickerList.sorted { $0.countryName < $1.countryName }
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
