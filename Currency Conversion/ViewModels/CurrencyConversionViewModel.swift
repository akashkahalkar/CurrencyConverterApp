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
    
    var dataSource = ConversionDataSource.empty {
        didSet { self.isLoading = false }
    }
    
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var base = "USD" {
        didSet {
            withAnimation {
                selectedCountryName = dataSource.getcountryName(code: base)
            }
        }
    }
    
    var selectedCountryName: String = "Select a Country"
    
    init(appId: String) {
        let urlManager = OERURLManager(appId)
        manager = RequestManager(manager: urlManager)
        coreDataManager = DataController.shared
        fetchData()
    }
}

extension CurrencyConversionViewModel {
    func fetchData(forceUpdate: Bool = true) {
        
        isLoading = true
        Task.detached(priority: .userInitiated) {
            
            async let countryNameData = self.loadCountryNameMapings()
            async let conversionData = self.loadConversionRateMappings(forceUpdate: forceUpdate)
            
            let nameData = await countryNameData
            let rateData = await conversionData
            
            
            guard !nameData.isEmpty, let rateData else {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = Constants.ErrorMessages.somthingWentWrong
                    self.dataSource = ConversionDataSource.empty
                }
                return
            }
            
            let mapping = await self.loadMapping(nameData, rateData)
            let base = rateData.base ?? "USD"
            let timestamp = rateData.timestamp
            let license = rateData.license ?? ""
            let disclaimer = rateData.disclaimer ?? ""
            
            await MainActor.run {
                self.dataSource = ConversionDataSource(
                    mappings: mapping,
                    base: base,
                    timestamp: timestamp,
                    license: license,
                    disclaimer: disclaimer)
                self.base = base
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
        let countryCodeMappings = coreDataManager.fetchCountryNameMapping()
        if countryCodeMappings.isEmpty {
            guard let response = await fetchCurrencies() else {
                return []
            }
            do {
                try await coreDataManager.saveCountryNameMappingToDb(response: response)
                isLoading = false
                errorMessage = ""
                return coreDataManager.fetchCountryNameMapping()
            } catch {
                isLoading = false
                errorMessage = Constants.ErrorMessages.somthingWentWrong
                return []
            }
        } else {
            return countryCodeMappings
        }
    }
    
    private func loadConversionRateMappings(forceUpdate: Bool) async -> ConversionRateMapping? {
        let currencyRates = coreDataManager.fetchConversionRateMappings()
        if currencyRates == nil || forceUpdate == true {
            guard let currencyRateResponse = await fetchLatestCurrencyRates() else {
                return nil
            }
            do {
                try await coreDataManager.saveToDb(response: currencyRateResponse)
                return coreDataManager.fetchConversionRateMappings()
            }
            catch {
                return nil
            }
        } else {
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
