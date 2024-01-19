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
    
    private func deleteIfAlreadyPresent() {
        
        let context = DataController.shared.container.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ConversionRateMapping")
        request.returnsObjectsAsFaults = false
        
        do {
            let result = try context.fetch(request)
            if result.count > 0 {
                for object in result {
                    context.delete(object as! NSManagedObject)
                }
                try context.save()
            }
        }
        catch {
            print("failed to save")
        }
    }
    
    func saveToDb(response: ConversionRateResponse) throws {
        deleteIfAlreadyPresent()
        let context = DataController.shared.container.viewContext
        let conversionRateMapping = ConversionRateMapping(context: context)
        conversionRateMapping.disclaimer = response.disclaimer
        conversionRateMapping.license = response.license
        conversionRateMapping.timestamp = response.timestamp
        
        response.rates.forEach({ (countryCode, amount) in
            if let conversionRate = NSEntityDescription.insertNewObject(
                forEntityName: "ConversionRates",
                into: context) as? ConversionRates {
                conversionRate.countryCode = countryCode
                conversionRate.conversionRate = amount
                conversionRateMapping.addToMapping(conversionRate)
            }
        })
        do {
            try context.save()
        }
        catch {
            throw OERError.Database.failedToSave
        }
    }
    
    func fetchConversionRateMappings() -> ConversionRateMapping? {
        var conversionRateMapping: ConversionRateMapping?
        let context = DataController.shared.container.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ConversionRateMapping")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request).first
            guard let data = result as? ConversionRateMapping else {
                return nil
            }
            conversionRateMapping = data
        } catch {
            conversionRateMapping = nil
        }
        return conversionRateMapping
    }
    
    func fetchCountryNameMapping() -> [ContryCodeMapping] {
        let context = DataController.shared.container.viewContext
        var pickerData = [ContryCodeMapping]()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ContryCodeMapping")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request) as? [ContryCodeMapping]
            pickerData = result?.compactMap({ $0 }) ?? []
        } catch {
            return pickerData
        }
        return pickerData
    }
}
