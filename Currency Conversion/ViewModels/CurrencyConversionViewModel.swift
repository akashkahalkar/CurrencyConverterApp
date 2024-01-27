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
        print("task started", Date().description, #function)
        let nameData = await self.loadCountryNameMapings()
        let rateData = await self.loadConversionRateMappings(forceUpdate: forceUpdate)
        print("task completed", Date().description, #function)
        
        guard !nameData.isEmpty, !rateData.isEmpty else {
            self.isLoading = false
            self.errorMessage = Constants.ErrorMessages.somthingWentWrong
            self.dataSource = ConversionDataSource.empty
            return
        }
        
        print("parsign started", Date().description, #function)
        let mapping = self.loadMapping(nameData, rateData)
        print("parsign completed", Date().description, #function)
//        let base = rateData.base ?? "USD"
//        let timestamp = rateData.timestamp
//        let license = rateData.license ?? ""
//        let disclaimer = rateData.disclaimer ?? ""
        
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
            print("Api call started", #function, Date().description)
            guard let response = await fetchCurrencies() else {
                print("Api call failed", #function)
                return [:]
            }
            print("Api call completed", #function, Date().description)
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
            print("return cached data", #function)
            return countryCodeMappings
        }
    }
    
    private func loadConversionRateMappings(forceUpdate: Bool) async -> [String: Double] {
        /// check core data for cached data
        let currencyRates = await coreDataManager.fetchConversionRateMappings()
        
        if currencyRates.isEmpty || forceUpdate == true {
            /// if no data, or force sync due to last sync threshold breach
            print("Force sync", forceUpdate)
            print("Api call started", #function, Date().description)
            guard let currencyRateResponse = await fetchLatestCurrencyRates() else {
                print("Api call failed", #function)
                return [:]
            }
            print("Api call completed", #function, Date().description)
            do {
                print("save to db call started", #function)
                print("response", currencyRateResponse)
                try await coreDataManager.saveToDb(response: currencyRateResponse)
                print("save to db call completed", #function)
                return await coreDataManager.fetchConversionRateMappings()
            }
            catch {
                print("Exception!!! \(error.localizedDescription)", #function)
                return [:]
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
