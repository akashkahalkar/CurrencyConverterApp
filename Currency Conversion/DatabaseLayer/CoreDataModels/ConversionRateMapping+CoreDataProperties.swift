//
//  ConversionRateMapping+CoreDataProperties.swift
//  Currency Conversion
//
//  Created by Akash Kahalkar on 11/06/22.
//
//

import Foundation
import CoreData


extension ConversionRateMapping {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConversionRateMapping> {
        return NSFetchRequest<ConversionRateMapping>(entityName: "ConversionRateMapping")
    }

    @NSManaged public var disclaimer: String?
    @NSManaged public var timestamp: Double
    @NSManaged public var base: String?
    @NSManaged public var license: String?
    @NSManaged public var mapping: NSSet?

}

// MARK: Generated accessors for mapping
extension ConversionRateMapping {

    @objc(addMappingObject:)
    @NSManaged public func addToMapping(_ value: ConversionRates)

    @objc(removeMappingObject:)
    @NSManaged public func removeFromMapping(_ value: ConversionRates)

    @objc(addMapping:)
    @NSManaged public func addToMapping(_ values: NSSet)

    @objc(removeMapping:)
    @NSManaged public func removeFromMapping(_ values: NSSet)

}

extension ConversionRateMapping : Identifiable {

}
