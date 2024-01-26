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
    func fetchData(forceUpdate: Bool = false) {
        
        isLoading = true
        Task {
            let countryNameData = await loadCountryNameMapings()
            guard let conversionData = await loadConversionRateMappings(forceUpdate: forceUpdate) else {
                
                isLoading = false
                errorMessage = Constants.ErrorMessages.somthingWentWrong
                dataSource = ConversionDataSource.empty
                return
            }
            
            DispatchQueue.main.async {
                self.dataSource = ConversionDataSource(countryCodeMapping: countryNameData,
                                                       conversionRateMapping: conversionData)
                self.base = self.dataSource.getBase()
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
