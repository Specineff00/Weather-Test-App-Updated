//
//  Weathers+CoreDataProperties.swift
//  
//
//  Created by Yogesh N Ramsorrrun on 09/01/2017.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Weathers {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Weathers> {
        return NSFetchRequest<Weathers>(entityName: "Weathers");
    }

    @NSManaged public var currentWeather: String?
    @NSManaged public var date: NSDate?
    @NSManaged public var lastUpdated: String?
    @NSManaged public var temperature: Float
    @NSManaged public var windDegrees: Float
    @NSManaged public var windSpeed: Float

}
