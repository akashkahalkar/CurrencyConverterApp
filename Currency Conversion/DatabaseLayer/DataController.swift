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
            print(error.localizedDescription)
        }
    }
    
    func saveToDb(response: ConversionRateResponse) async throws {
        
        try await container.performBackgroundTask { context in
            
            self.deleteIfAlreadyPresent(context: context)
            let conversionRateMapping = ConversionRateMapping(context: context)
            conversionRateMapping.disclaimer = response.disclaimer
            conversionRateMapping.license = response.license
            conversionRateMapping.timestamp = response.timestamp
            
            response.rates.forEach { (countryCode, amount) in
                let conversionRate = ConversionRates(context: context)
                conversionRate.countryCode = countryCode
                conversionRate.conversionRate = amount
                conversionRateMapping.addToMapping(conversionRate)
            }
            do {
                try context.save()
            }
            catch {
                throw OERError.Database.failedToSave
            }
        }
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
                print(error.localizedDescription)
                throw OERError.Database.failedToSave
            }
        }
    }
    
    func fetchConversionRateMappings() -> ConversionRateMapping? {
        let request = ConversionRateMapping.fetchRequest()
        return try? viewContext.fetch(request).first
    }
    
    func fetchCountryNameMapping() -> [ContryCodeMapping] {
        let request = ContryCodeMapping.fetchRequest()
        let result = try? viewContext.fetch(request)
        return result?.compactMap({ $0 }) ?? []
    }
    
}

