//
//  ContryCodeMapping+CoreDataProperties.swift
//  Currency Conversion
//
//  Created by Akash Kahalkar on 11/06/22.
//
//

import Foundation
import CoreData


extension ContryCodeMapping {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ContryCodeMapping> {
        return NSFetchRequest<ContryCodeMapping>(entityName: "ContryCodeMapping")
    }
    @NSManaged public var countryCode: String?
    @NSManaged public var countryName: String?
}

extension ContryCodeMapping : Identifiable {

}
