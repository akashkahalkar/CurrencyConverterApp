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
    
    var dataSource = ConversionDataSource(countryCodeMapping: [],
                                          conversionRateMapping: nil) {
        didSet {
            isLoading = false
        }
    }
    
    @Published var base = "USD" {
        didSet {
            withAnimation {
                selectedCountryName = dataSource.getcountryName(code: base)
            }
        }
    }
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
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
        Task {
            isLoading = true
            let countryNameData = await loadCountryNameMapings()
            guard let conversionData = await loadConversionRateMappings(forceUpdate: forceUpdate) else {
                
                isLoading = false
                errorMessage = Constants.ErrorMessages.somthingWentWrong
                dataSource = ConversionDataSource(countryCodeMapping: [],
                                                  conversionRateMapping: nil)
                return
            }
            dataSource = ConversionDataSource(countryCodeMapping: countryNameData,
                                              conversionRateMapping: conversionData)
            self.base = dataSource.getBase()
        }

    }
    
    func parseAmount(_ s: String) -> (amount: Double?, error: String) {
        if let amount = Double(s.trimmingCharacters(in: .whitespacesAndNewlines)) {
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
                try saveCountryNameMappingToDb(response: response)
                isLoading = false
                errorMessage = ""
                return coreDataManager.fetchCountryNameMapping()
            }
            catch {
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
                try coreDataManager.saveToDb(response: currencyRateResponse)
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
        do {
            guard let conversionRatesResponse = try await manager.getLatestConversionRate() else {
                return nil
            }
            return conversionRatesResponse
        }
        catch {
            return nil
        }
    }
    
    private func fetchCurrencies() async -> CurrenciesResponse? {
        do {
            guard let currenciesResponse = try await manager.getCurrencies() else {
                return nil
            }
            return currenciesResponse
        }
        catch {
            return nil
        }
    }
    
    private func saveCountryNameMappingToDb(response: CurrenciesResponse) throws {
        response.forEach { (key, value) in
            if let countryCodeMappings = NSEntityDescription.insertNewObject(
                forEntityName: "ContryCodeMapping",
                into: coreDataManager.container.viewContext) as? ContryCodeMapping {
                countryCodeMappings.countryCode = key
                countryCodeMappings.countryName = value
            }
        }
        do {
            try coreDataManager.container.viewContext.save()
        } catch {
            throw OERError.Database.failedToSave
        }
    }
}
