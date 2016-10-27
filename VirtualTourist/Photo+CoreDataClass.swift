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

}
