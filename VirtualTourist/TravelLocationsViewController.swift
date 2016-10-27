//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by DONALD CHWOJKO on 10/24/16.
//  Copyright © 2016 DONALD CHWOJKO. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController {

    var stack: CoreDataStack!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    var bEditMode: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // get core data stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        stack = delegate.stack
        
        // SET MAPVIEW DELEGATE
        mapView.delegate = self
        
        // RESTORE MAP VIEW
        restoreMapView()
        
        //
        restorePins()
        
    }
    
    func restoreMapView() {
        // TO DO: get previous region and zoom level
        let defaultManager = UserDefaults.standard
        if let longitude = defaultManager.object(forKey: "longitude") as? CLLocationDegrees, let latitude = defaultManager.object(forKey: "latitude") as? CLLocationDegrees, let longitudeSpan = defaultManager.object(forKey: "longitudeSpan") as? CLLocationDegrees, let latitudeSpan = defaultManager.object(forKey: "latitudeSpan") as? CLLocationDegrees {
            mapView.region.center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            mapView.region.span = MKCoordinateSpan(latitudeDelta: latitudeSpan, longitudeDelta: longitudeSpan)
        }
    }
    
    func saveMapView() {
        let defaultManager = UserDefaults.standard
        defaultManager.set(mapView.region.center.longitude, forKey: "longitude")
        defaultManager.set(mapView.region.center.latitude, forKey: "latitude")
        defaultManager.set(mapView.region.span.longitudeDelta, forKey: "longitudeSpan")
        defaultManager.set(mapView.region.span.latitudeDelta, forKey: "latitudeSpan")
    }
    
    func restorePins() {
        let pins = getPins()
        for pin in pins {
            dropPin(longitude: pin.longitude, latitude: pin.latitude)
        }
    }
    
    func getPins() -> [Pin] {
        // TO DO: 
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        do {
            let pins = try stack.mainContext.fetch(fetchRequest)
            return pins
        } catch {
            print("There was a problem fetching pins")
            return [Pin]()
        }
    }

    @IBAction func editButtonAction(_ sender: UIBarButtonItem) {
        if (bEditMode) {
            bEditMode = false
            editButton.title = "Edit"
        } else {
            bEditMode = true
            editButton.title = "Done"
        }
    }
    @IBAction func longPressAction(_ sender: UILongPressGestureRecognizer) {
        // Only do something if not in edit mode
        if (!bEditMode) {
            // Only drop on begin long press
            if (sender.state == UIGestureRecognizerState.began) {
                let touchPoint = sender.location(in: mapView)
                let coordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
                
                dropPin(longitude: coordinates.longitude, latitude: coordinates.latitude)
                createPinObject(longitude: coordinates.longitude, latitude: coordinates.latitude)
            }
            
            // TO DO: Handle drag and drop pin
            if (sender.state == UIGestureRecognizerState.changed) {
                // update pin coordinates
            }
            
            if (sender.state == UIGestureRecognizerState.ended) {
                // persist the pin object
            }
        }
    }
    
    func dropPin(longitude: Double, latitude: Double) {
        let annotation = MKPointAnnotation()
        annotation.coordinate.longitude = longitude
        annotation.coordinate.latitude = latitude
        mapView.addAnnotation(annotation)
    }
    
    func createPinObject(longitude: Double, latitude: Double) {
        let entity = NSEntityDescription.entity(forEntityName: "Pin", in: stack.mainContext)
        let pin = NSManagedObject(entity: entity!, insertInto: stack.mainContext)
        pin.setValue(longitude, forKey: "longitude")
        pin.setValue(latitude, forKey: "latitude")
        stack.save()
    }
   
}

extension TravelLocationsViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier: String = "Pin"
        var view: MKPinAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = false
            view.animatesDrop = true
            view.isDraggable = false
            view.pinTintColor = UIColor.orange
        }
        return view
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if (bEditMode) {
            // DESELECT ANNOTATION
            mapView.deselectAnnotation(view.annotation, animated: false)
            
            // REMOVE FROM CORE DATA
            if let pin = getPinWithCoordinates(longitude: (view.annotation?.coordinate.longitude)!, latitude: (view.annotation?.coordinate.latitude)!) {
                stack.mainContext.delete(pin)
            }
            
            // REMOVE FROM VIEW
            mapView.removeAnnotation(view.annotation!)
        } else {
            
            // TO DO: INSTANTIATE NEXT CONTROLLER AND PUSH
            let controller = self.storyboard?.instantiateViewController(withIdentifier: "photoAlbumViewController") as! PhotoAlbumViewController
            controller.selectedPin = getPinWithCoordinates(longitude: (view.annotation?.coordinate.longitude)!, latitude: (view.annotation?.coordinate.latitude)!)
            controller.mapView = mapView
            
            // DESELECT ANNOTATION
            mapView.deselectAnnotation(view.annotation, animated: false)
            
            self.navigationController?.pushViewController(controller, animated: true)
            
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapView()
    }
    
    func getPinWithCoordinates(longitude: Double, latitude: Double) -> Pin? {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let predicate = NSPredicate(format: "longitude == %@ AND latitude == %@", argumentArray: [longitude, latitude])
        fetchRequest.predicate = predicate
        do {
            let searchResults = try stack.mainContext.fetch(fetchRequest)
            if (searchResults.count > 0) {
                return searchResults[0]
            } else {
                return nil
            }
        } catch {
            print("There was a problem getting pin with specified coordinates")
            return nil
        }
    }
}

