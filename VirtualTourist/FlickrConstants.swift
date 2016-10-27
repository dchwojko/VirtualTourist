//
//  FlickrConstants.swift
//  VirtualTouristSwift3.0
//
//  Created by DONALD CHWOJKO on 10/4/16.
//  Copyright © 2016 DONALD CHWOJKO. All rights reserved.
//

import Foundation

extension FlickrClient {
    struct Constants {
        static let ApiScheme = "https"
        static let ApiHost = "api.flickr.com"
        static let ApiPath = "/services/rest"
        static let ApiKey = "b175d4cb8753f89ba81a139235f9622f"
    }
    
    struct ParameterKeys {
        static let METHOD = "method"
        static let APIKEY = "api_key"
        static let FORMAT = "format"
        static let NOJSONCALLBACK = "nojsoncallback"
        static let BBOX = "bbox"
        static let EXTRAS = "extras"
        static let PERPAGE = "per_page"
        static let PAGE = "page"
    }
    
}
