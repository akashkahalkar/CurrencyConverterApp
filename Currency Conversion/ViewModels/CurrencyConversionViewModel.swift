//
//  ContentViewViewModel.swift
//  Currency Conversion
//
//  Created by Akash Kahalkar on 11/06/22.
//

import Foundation
import CoreData
import SwiftUI


@MainActor
class CurrencyConversionViewModel: ObservableObject {
    
    private let manager: RequestManager
    private let coreDataManager: DataController
    
    var dataSource = ConversionDataSource.empty
    
    @Published var errorMessage: String?
    @Published var isLoading: Bool = true
    @Published var base = "USD"
    @Published var pickerData: [CountryListPickerData] = []
    
    init(appId: String) {
        let urlManager = OERURLManager(appId)
        manager = RequestManager(manager: urlManager)
        coreDataManager = DataController.shared
        //fetchData()
    }
}

extension CurrencyConversionViewModel {
    func fetchData(forceUpdate: Bool = false) {
        
        isLoading = true
        Task {
            print("task started", Date().description, #function)
            let nameData = await self.loadCountryNameMapings()
            let rateData = await self.loadConversionRateMappings(forceUpdate: forceUpdate)
            print("task completed", Date().description, #function)
            
            guard !nameData.isEmpty, let rateData else {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = Constants.ErrorMessages.somthingWentWrong
                    self.dataSource = ConversionDataSource.empty
                }
                return
            }
            
            print("parsign started", Date().description, #function)
            let mapping = self.loadMapping(nameData, rateData)
            print("parsign completed", Date().description, #function)
            let base = rateData.base ?? "USD"
            let timestamp = rateData.timestamp
            let license = rateData.license ?? ""
            let disclaimer = rateData.disclaimer ?? ""
            
            DispatchQueue.main.async {
                self.dataSource = ConversionDataSource(
                    mappings: mapping,
                    base: base,
                    timestamp: timestamp,
                    license: license,
                    disclaimer: disclaimer)
                self.base = base
                self.pickerData = self.dataSource.getCountryCodes()
                self.isLoading = false
                self.errorMessage = ""
            }
        }
    }
    
    func parseAmount(_ s: String) -> (amount: Double?, error: String) {
        if let amount = Double(s.trimmingCharacters(in: .whitespacesAndNewlines)),
            amount < 1000000 {
            return (amount, "")
        } else {
            return (nil, Constants.ErrorMessages.EnterValidAmount)
        }
    }
    
    private func loadCountryNameMapings() async -> [ContryCodeMapping] {
        /// check in core data for cached data
        let countryCodeMappings = coreDataManager.fetchCountryNameMapping()
        
        if countryCodeMappings.isEmpty {
            /// if no data is cached then make an API call
            print("Api call completed", #function, Date().description)
            guard let response = await fetchCurrencies() else {
                print("Api call failed", #function)
                return []
            }
            print("Api call completed", #function, Date().description)
            do {
                /// saving to core Data
                try await coreDataManager.saveCountryNameMappingToDb(response: response)
                /// fetch and return from core data
                return coreDataManager.fetchCountryNameMapping()
            } catch {
                return []
            }
        } else {
            print("return cached data", #function)
            return countryCodeMappings
        }
    }
    
    private func loadConversionRateMappings(forceUpdate: Bool) async -> ConversionRateMapping? {
        /// check core data for cached data
        let currencyRates = coreDataManager.fetchConversionRateMappings()
        
        if currencyRates == nil || forceUpdate == true {
            /// if no data, or force sync due to last sync threshold breach
            print("Force sync", forceUpdate)
            print("Api call started", #function, Date().description)
            guard let currencyRateResponse = await fetchLatestCurrencyRates() else {
                print("Api call failed", #function)
                return nil
            }
            print("Api call completed", #function, Date().description)
            do {
                print("save to db call started", #function)
                try await coreDataManager.saveToDb(response: currencyRateResponse)
                print("save to db call completed", #function)
                return coreDataManager.fetchConversionRateMappings()
            }
            catch {
                print("Exception!!! \(error.localizedDescription)", #function)
                return nil
            }
        } else {
            print("return cached data", #function)
            return currencyRates
        }
    }
    
    private func fetchLatestCurrencyRates() async -> ConversionRateResponse? {
        try? await manager.getLatestConversionRate()
    }
    
    private func fetchCurrencies() async -> CountryCodeMapping? {
        try? await manager.getCurrencies()
    }
    
}
extension CurrencyConversionViewModel {
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
        _ countryNameData: [ContryCodeMapping],
        _ rateData: ConversionRateMapping
    ) -> [String: (String, Double)] {
        
        let countryNameMapping = self.loadCountryNameMapping(objects: countryNameData)
        let conversionRateMapping = self.loadConversionRateMapping(object: rateData)
    
        var mergedDictionary = [String: (String, Double)]()
        for countryCode in Set(countryNameMapping.keys).intersection(conversionRateMapping.keys) {
            // Get values from both dictionaries
            if let name = countryNameMapping[countryCode], let value = conversionRateMapping[countryCode] {
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
