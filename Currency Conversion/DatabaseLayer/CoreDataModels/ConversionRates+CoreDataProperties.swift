//
//  ConversionRates+CoreDataProperties.swift
//  Currency Conversion
//
//  Created by Akash Kahalkar on 11/06/22.
//
//

import Foundation
import CoreData


extension ConversionRates {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConversionRates> {
        return NSFetchRequest<ConversionRates>(entityName: "ConversionRates")
    }

    @NSManaged public var countryCode: String?
    @NSManaged public var conversionRate: Double

}

extension ConversionRates : Identifiable {

}
