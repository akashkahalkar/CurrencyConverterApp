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
    
    func saveToDb(response: ConversionRateResponse) async throws {
        
        let backgrounContext = backgroundContext
        do {
            try await backgroundContext.perform {
                self.deleteIfAlreadyPresent(context: backgrounContext)
                let conversionRateMapping = ConversionRateMapping(context: self.backgroundContext)
                conversionRateMapping.disclaimer = response.disclaimer
                conversionRateMapping.license = response.license
                conversionRateMapping.timestamp = response.timestamp
                
                response.rates.forEach { (countryCode, amount) in
                    let conversionRate = ConversionRates(context: self.backgroundContext)
                    conversionRate.countryCode = countryCode
                    conversionRate.conversionRate = amount
                    conversionRateMapping.addToMapping(conversionRate)
                }
                try backgrounContext.save()
            }
        } catch {
            print(error.localizedDescription, #function)
        }
        
        
        
//        try await container.performBackgroundTask { context in
//            
//            self.deleteIfAlreadyPresent(context: context)
//            let conversionRateMapping = ConversionRateMapping(context: context)
//            conversionRateMapping.disclaimer = response.disclaimer
//            conversionRateMapping.license = response.license
//            conversionRateMapping.timestamp = response.timestamp
//            
//            response.rates.forEach { (countryCode, amount) in
//                let conversionRate = ConversionRates(context: context)
//                conversionRate.countryCode = countryCode
//                conversionRate.conversionRate = amount
//                conversionRateMapping.addToMapping(conversionRate)
//            }
//            do {
//                try context.save()
//            }
//            catch {
//                print(error.localizedDescription, #function)
//                throw OERError.Database.failedToSave
//            }
//        }
    }
    
    func saveCountryNameMappingToDb(response: CountryCodeMapping) async throws {
        
        try await container.performBackgroundTask { context in
            do {
                response.forEach { (key, value) in
                    if let countryCodeMappings = NSEntityDescription.insertNewObject(
                        forEntityName: "ContryCodeMapping",
                        into: self.viewContext) as? ContryCodeMapping {
                        countryCodeMappings.countryCode = key
                        countryCodeMappings.countryName = value
                    }
                }
                try self.viewContext.save()
            } catch {
                print(error.localizedDescription, #function)
                throw OERError.Database.failedToSave
            }
        }
    }
    
    func fetchConversionRateMappings() async -> [String : Double] {
        
        let backgroundContext = backgroundContext
        do {
            let request = ConversionRateMapping.fetchRequest()
            return try await backgroundContext.perform {
                let object = try backgroundContext.fetch(request).first
                return self.loadConversionRateMapping(object: object)
            }
        } catch {
            print(error.localizedDescription, #function)
            return [:]
        }
    }
    
    func fetchCountryNameMapping() async -> [String: String] {
        let backgroundContext = backgroundContext
        do {
            return try await backgroundContext.perform {
                let request = ContryCodeMapping.fetchRequest()
                let objects = try backgroundContext.fetch(request).compactMap{$0}
                return self.loadCountryNameMapping(objects: objects)
            }
        } catch {
            print(error.localizedDescription, #function)
            return [:]
        }
    }
    
    private func loadCountryNameMapping(objects: [ContryCodeMapping]) -> [String: String] {
        
        var map: [String: String] = [:]
        
        objects.forEach { ccm in
            if let code = ccm.countryCode, let name = ccm.countryName  {
                print(code, name)
                map[code] =  name
            }
        }
        return map
    }
    
    private func loadConversionRateMapping(object: ConversionRateMapping?) -> [String: Double] {
        
        var rateMapping: [String: Double] = [:]
        let conversionRates: [ConversionRates] = object?.mapping?.compactMap{$0 as? ConversionRates} ?? []
        
        guard !conversionRates.isEmpty else {
            return [:]
        }
        
        conversionRates.forEach { rate in
            if let countryCode = rate.countryCode {
                print(countryCode, rate.conversionRate)
                rateMapping[countryCode] = rate.conversionRate
            }
        }
        return rateMapping
    }
}

