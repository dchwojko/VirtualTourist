//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by DONALD CHWOJKO on 10/24/16.
//  Copyright © 2016 DONALD CHWOJKO. All rights reserved.
//

import Foundation
import CoreData
import UIKit


public class Photo: NSManagedObject {
    
    var image: UIImage? {
        get {
            if let imageData = imageData {
                return UIImage(data: imageData as Data)
            } else {
                return nil
            }
        }
    }
    

    
    static func photosFromArrayOfDictionaries(dictionaries: [[String:AnyObject]], context: NSManagedObjectContext) -> [Photo] {
        var photos = [Photo]()
        for photoDictionary in dictionaries {
            
            
            context.performAndWait({
                let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context)
                let photo = NSManagedObject(entity: entity!, insertInto: context) as! Photo
                photo.imagePath = photoDictionary["url_m"] as? String
                photos.append(photo)
            })
        }
        return photos
    }
    
    
    
    
    
    

}
