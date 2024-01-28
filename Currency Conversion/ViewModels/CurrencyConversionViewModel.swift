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
    
    @Published var dataSource = ConversionDataSource.empty    
    @Published var errorMessage: String?
    @Published var isLoading: Bool = true
    @Published var base = "USD"
    @Published var pickerData: [CountryListPickerData] = []
    
    init(appId: String) {
        let urlManager = OERURLManager(appId)
        manager = RequestManager(manager: urlManager)
        coreDataManager = DataController.shared
    }
}

extension CurrencyConversionViewModel {
    func fetchData(forceUpdate: Bool = false) async {
        
        isLoading = true
        let nameData = await self.loadCountryNameMapings()
        let rateData = await self.loadConversionRateMappings(forceUpdate: forceUpdate)
        
        guard !nameData.isEmpty, !rateData.isEmpty else {
            self.isLoading = false
            self.errorMessage = Constants.ErrorMessages.somthingWentWrong
            self.dataSource = ConversionDataSource.empty
            return
        }
        
        let mapping = self.loadMapping(nameData, rateData)
        
        self.dataSource = ConversionDataSource(
            mappings: mapping,
            base: "USD",
            timestamp: 0,
            license: "license",
            disclaimer: "disclaimer")
        self.base = base
        self.pickerData = self.dataSource.getCountryCodes()
        self.isLoading = false
        self.errorMessage = ""
    }
    
    func parseAmount(_ s: String) -> (amount: Double?, error: String) {
        if let amount = Double(s.trimmingCharacters(in: .whitespacesAndNewlines)),
            amount < 1000000 {
            return (amount, "")
        } else {
            return (nil, Constants.ErrorMessages.EnterValidAmount)
        }
    }
    
    private func loadCountryNameMapings() async -> [String : String] {
        /// check in core data for cached data
        let countryCodeMappings = await coreDataManager.fetchCountryNameMapping()
        
        if countryCodeMappings.isEmpty {
            /// if no data is cached then make an API call
            guard let response = await fetchCurrencies() else {
                return [:]
            }
            do {
                /// saving to core Data
                try await coreDataManager.saveCountryNameMappingToDb(response: response)
                /// fetch and return from core data
                return await coreDataManager.fetchCountryNameMapping()
            } catch {
                print(error.localizedDescription, #function)
                return [:]
            }
        } else {
            return countryCodeMappings
        }
    }
    
    private func loadConversionRateMappings(forceUpdate: Bool) async -> [String: Double] {
        /// check core data for cached data
        let currencyRates = await coreDataManager.fetchConversionRateMappings()
        if currencyRates.isEmpty || forceUpdate {
            /// if no data, or force sync due to last sync threshold breach
            guard let currencyRateResponse = await fetchLatestCurrencyRates() else {
                return [:]
            }
            do {
                try await coreDataManager.saveToDb(response: currencyRateResponse)
                return await coreDataManager.fetchConversionRateMappings()
            }
            catch {
                return [:]
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
    
    private func loadMapping(
        _ countryNameData: [String: String],
        _ rateData: [String: Double]
    ) -> [String: (String, Double)] {
        
        var mergedDictionary = [String: (String, Double)]()
        for countryCode in Set(countryNameData.keys).intersection(rateData.keys) {
            // Get values from both dictionaries
            if let name = countryNameData[countryCode], let value = rateData[countryCode] {
                // Create a tuple and add it to the merged dictionary
                mergedDictionary[countryCode] = (name, value)
            }
        }
        return mergedDictionary
    }
}
