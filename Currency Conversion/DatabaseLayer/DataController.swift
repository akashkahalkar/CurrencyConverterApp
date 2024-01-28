//
//  DataController.swift
//  Currency Conversion
//
//  Created by Akash Kahalkar on 11/06/22.
//

import Foundation
import CoreData

class DataController: ObservableObject {
    let container: NSPersistentContainer
    static let shared: DataController = DataController()
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    var backgroundContext: NSManagedObjectContext {
        container.newBackgroundContext()
    }
        
    private init() {
        container = NSPersistentContainer(name: "CurrencyConverterModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }    
}

extension DataController {
    
    private func deleteIfAlreadyPresent(context: NSManagedObjectContext) {
        
        context.performAndWait {
            let request = ConversionRateMapping.fetchRequest()
            request.returnsObjectsAsFaults = false
            
            do {
                var result = try context.fetch(request)
                if !result.isEmpty {
                    result.removeAll()
                    try context.save()
                }
            }
            catch {
                print(error.localizedDescription, #function)
            }
        }
    }
    
    func saveToDb(response: ConversionRateResponse) async throws {
        
        var rateMappings = [String: Double]()
        do {
            return try await container.performBackgroundTask { context in
                
                self.deleteIfAlreadyPresent(context: context)
                
                let conversionRateMapping = ConversionRateMapping(context: context)
                conversionRateMapping.disclaimer = response.disclaimer
                conversionRateMapping.license = response.license
                conversionRateMapping.timestamp = response.timestamp
                
                response.rates.forEach { (countryCode, amount) in
                    let conversionRate = ConversionRates(context: context)
                    conversionRate.countryCode = countryCode
                    conversionRate.conversionRate = amount
                    rateMappings[countryCode] = amount
                    conversionRateMapping.addToMapping(conversionRate)
                }
                try context.save()
            }
        } catch {
            print(error.localizedDescription, #function)
        }
    }
    
    func saveCountryNameMappingToDb(response: CountryCodeMapping) async throws {
        
        try await container.performBackgroundTask { context in
            do {
                response.forEach { (key, value) in
                    let countryCodeMappings = ContryCodeMapping(context: context)
                    countryCodeMappings.countryCode = key
                    countryCodeMappings.countryName = value
                }
                try context.save()
            } catch {
                print(error.localizedDescription, #function)
                throw OERError.Database.failedToSave
            }
        }
    }
    
    func fetchConversionRateMappings() async -> [String : Double] {
        do {
            return try await container.performBackgroundTask { context in
                let request = ConversionRateMapping.fetchRequest()
                let object = try context.fetch(request).first
                return self.loadConversionRateMapping(object: object)
            }
        } catch {
            print(error.localizedDescription, #function)
            return [:]
        }
    }
    
    func fetchCountryNameMapping() async -> [String: String] {

        do {
            return try await container.performBackgroundTask { context in
                let request = ContryCodeMapping.fetchRequest()
                let objects = try context.fetch(request).compactMap{$0}
                return self.loadCountryNameMapping(objects: objects)
            }
        } catch {
            print(error.localizedDescription, #function)
            return [:]
        }
    }
    
    private func loadCountryNameMapping(objects: [ContryCodeMapping]) -> [String: String] {
        
        return objects.reduce(into: [String: String]()) { partialResult, object in
            if let code = object.countryCode, let name = object.countryName {
                partialResult[code] = name
            }
        }
    }
    
    private func loadConversionRateMapping(object: ConversionRateMapping?) -> [String: Double] {
        
        let conversionRates: [ConversionRates] = object?.mapping?.compactMap{$0 as? ConversionRates} ?? []
        
        guard !conversionRates.isEmpty else {
            return [:]
        }
        
        return conversionRates.reduce(into: [String: Double]()) { partialResult, object in
            if let code = object.countryCode {
                partialResult[code] = object.conversionRate
            }
        }
    }
}

