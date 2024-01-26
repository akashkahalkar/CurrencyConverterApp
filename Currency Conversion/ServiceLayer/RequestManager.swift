//
//  RequestManager.swift
//  Currency Conversion
//
//  Created by Akash Kahalkar on 10/06/22.
//

import Foundation

class RequestManager {
    //this could have been a singleton but avoided due to injection
    private var urlManager: OERURLManager
    
    init(manager: OERURLManager) {
        self.urlManager = manager
    }
    
    private func get<type: Codable>(url: URL) async throws -> type {
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                      throw OERError.API.invalidServerResponse
            }
            return try JSONDecoder().decode(type.self, from: data)
        }
        catch {
            throw OERError.API.somthingWentWrong
        }
    }
    
    func getLatestConversionRate(base: String = "USD") async throws -> ConversionRateResponse? {
        guard let url = urlManager.getLatestRateUrl(base: base) else {
            throw OERError.API.invalidUrl
        }
        return try await get(url: url)
    }
    
    func getCurrencies() async throws -> CountryCodeMapping? {
        guard let url = urlManager.getCurrencies() else {
            return nil
        }
        return try await get(url: url)
    }
}

struct OERURLManager {
    
    private let appId: String
    
    init(_ appId: String) {
        self.appId = appId
    }

    func getLatestRateUrl(base: String = "USD") -> URL? {
        let queryItems = [
            URLQueryItem(name: "app_id", value: appId),
            URLQueryItem(name: "base", value: base)
        ]
        let urlString = OpenExchangeRateUrl.baseUrl + OpenExchangeRateUrl.Paths.latestRates
        var urlComps = URLComponents(string: urlString)
        urlComps?.queryItems = queryItems
        return urlComps?.url
    }
    
    func getCurrencies() -> URL? {
        let urlString = OpenExchangeRateUrl.baseUrl + OpenExchangeRateUrl.Paths.currencies
        let urlComps = URLComponents(string: urlString)
        return urlComps?.url
    }
}

extension OERURLManager {
    enum OpenExchangeRateUrl {
        static let baseUrl = "https://openexchangerates.org"
        enum Paths {
            static let latestRates = "/api/latest.json"
            static let currencies = "/api/currencies.json"
        }
    }
}

enum OERError {
    enum API: Error {
        case invalidUrl
        case invalidServerResponse
        case somthingWentWrong
    }
    enum Database: Error {
        case failedToSave
    }
}
