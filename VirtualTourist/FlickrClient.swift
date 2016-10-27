//
//  FlickrClient.swift
//  VirtualTouristSwift3.0
//
//  Created by DONALD CHWOJKO on 10/4/16.
//  Copyright © 2016 DONALD CHWOJKO. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class FlickrClient: NSObject {
    var session = URLSession.shared
    
    // OK
    private func escapedParameters(parameters: [String:AnyObject]) -> String {
        if parameters.isEmpty {
            return ""
        } else {
            var keyValuePairs = [String]()
            for (key, value) in parameters {
                let stringValue = "\(value)"
                let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
            }
            return "?\(keyValuePairs.joined(separator: "&"))"
        }
    }
    
    func taskForGETMethod(urlString: String, parameters: [String:AnyObject], completionHandlerForGET: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {

        let url: URL = URL(string: urlString + escapedParameters(parameters: parameters))!
    
        let request = NSMutableURLRequest(url: url as! URL)
        request.httpMethod = "GET"
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            // helper function
            func sendError(error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard error == nil else {
                sendError(error: "There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2xx response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode , statusCode >= 200 && statusCode <= 299 else {
                sendError(error: "Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError(error: "No data was returned by the request!")
                return
            }
            
            let parsedResult: AnyObject!
            
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
                completionHandlerForGET(parsedResult, nil)
            } catch let error as NSError {
                completionHandlerForGET(nil, error)
                return
            }
            
        }
        task.resume()
        return task
    }
    
    // MARK: Shared Instance

    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
    func photosForPin(pin: Pin, context: NSManagedObjectContext, completionHandler: @escaping (_ photos: [Photo]?, _ error: NSError?) -> Void) {
        
        let bbox: String = "\(pin.longitude),\(pin.latitude),\(pin.longitude + 0.5),\(pin.latitude + 0.5)"
        var parameters: [String:AnyObject] = [
            FlickrClient.ParameterKeys.METHOD : "flickr.photos.search" as String as AnyObject,
            FlickrClient.ParameterKeys.APIKEY : FlickrClient.Constants.ApiKey as AnyObject,
            FlickrClient.ParameterKeys.FORMAT : "json" as AnyObject,
            FlickrClient.ParameterKeys.NOJSONCALLBACK : "1" as AnyObject,
            FlickrClient.ParameterKeys.BBOX : bbox as AnyObject,
            FlickrClient.ParameterKeys.EXTRAS : "url_m" as AnyObject,
            FlickrClient.ParameterKeys.PERPAGE : "21" as AnyObject,
            ]
        let urlStringBase: String = "https://api.flickr.com/services/rest/"
        var urlString: String = urlStringBase + escapedParameters(parameters: parameters)
        
        getNumberOfPages(urlString: urlString) { (pages, error) in
            guard error == nil else {
                completionHandler(nil, error)
                return
            }
            
            let randomPage = Int(arc4random_uniform(UInt32(pages)) + 1)
            
            parameters["page"] = randomPage as AnyObject?
            
            
            urlString = urlStringBase + self.escapedParameters(parameters: parameters)
            
            self.taskForGETMethod(urlString: urlString, parameters: parameters) { (result, error) in
                guard error == nil else {
                    print("There was a problem retrieving data")
                    completionHandler(nil, error)
                    return
                }
                
                
                if let result = result {
                    if let photosDictionary = result["photos"] as? [String: AnyObject] {
                        if let photoArrayOfDictionaries = photosDictionary["photo"] as? [[String:AnyObject]] {
                            var photos = [Photo]()
                            for photoDictionary in photoArrayOfDictionaries {
                                
                                if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
                                    let photo = NSManagedObject(entity: entity, insertInto: context) as! Photo
                                    photo.imagePath = photoDictionary["url_m"] as! String?
                                    photos.append(photo)
                                } else {
                                    fatalError("Could not find entity")
                                }
                                
                                do {
                                    try context.save()
                                } catch {
                                    fatalError("Failure to save context: \(error)")
                                }
                            }
                            
                            completionHandler(photos, nil)
                            return
                        }
                    }
                }
                
                completionHandler(nil, error)
                return
            }
        }
        
    }
    
    func getPhoto(photo: Photo, completionHandler: @escaping (_ imageData: NSData?, _ error: NSError?) -> Void) {
        
        let parameters: [String:AnyObject] = [:]
        
        let url = NSURL(string: photo.imagePath!)
        
        let request = NSMutableURLRequest(url: url as! URL)
        request.httpMethod = "GET"
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            // helper function
            func sendError(error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandler(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard error == nil else {
                sendError(error: "There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2xx response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode , statusCode >= 200 && statusCode <= 299 else {
                sendError(error: "Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError(error: "No data was returned by the request!")
                return
            }

            completionHandler(data as NSData, nil)
            return
        }
        task.resume()

    }
    
    func getNumberOfPages(urlString: String, completionHandler: @escaping (_ pages: Int, _ error: NSError?) -> Void) {
        let parameters: [String:AnyObject] = [:]
        taskForGETMethod(urlString: urlString, parameters: parameters) { (result, error) in
            guard error == nil else {
                print("There was an error getting the number of pages")
                completionHandler(0, error)
                return
            }
            
            if let result = result {
                if let photosDictionary = result["photos"] as? [String: AnyObject] {
                    if let pageCount = photosDictionary["pages"] {
                        
                        completionHandler(pageCount as! Int, nil)
                        return
                    }
                }
            }
            
            print("There was an error")
            completionHandler(0, nil)
            return
        }
    }
}
