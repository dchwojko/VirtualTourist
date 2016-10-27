//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by DONALD CHWOJKO on 10/24/16.
//  Copyright © 2016 DONALD CHWOJKO. All rights reserved.
//

import Foundation
import CoreData

extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var imagePath: String?
    @NSManaged public var imageData: NSData?
    @NSManaged public var pin: Pin?

}
