//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by DONALD CHWOJKO on 10/24/16.
//  Copyright © 2016 DONALD CHWOJKO. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {

    var stack: CoreDataStack!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    let reuseIdentifier: String = "Cell"
    
    var photos = [Photo]()
    var selectedPin : Pin!
    var selectedIndexes = [IndexPath]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get core data stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        stack = delegate.stack
        
        updateMapView()
        
        if (selectedPin == nil) {
            fatalError("selectedPin is nil")
        }
        
        // SET COLLECTION VIEW DELEGATE & DATA SOURCE
        collectionView.delegate = self
        collectionView.dataSource = self

        newCollectionButton.titleLabel?.text = "New Collection"
        
        if (selectedPin.photos?.count == 0) {
            newCollectionButton.isEnabled = false
            getPhotosForPin()
        } else {
            for photo in selectedPin.photos! {
                photos.append(photo as! Photo)
            }
        }
        // Do any additional setup after loading the view.
    }
    
    func updateMapView() {
        let initialLocation = CLLocationCoordinate2D(latitude: selectedPin.latitude, longitude: selectedPin.longitude)
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(initialLocation, regionRadius * 10.0, regionRadius * 10.0)
        mapView.setRegion(coordinateRegion, animated: false)
        mapView.isUserInteractionEnabled = false
        
        dropPin(longitude: selectedPin.longitude, latitude: selectedPin.latitude)
    }
    
    func dropPin(longitude: Double, latitude: Double) {
        let annotation = MKPointAnnotation()
        annotation.coordinate.longitude = longitude
        annotation.coordinate.latitude = latitude
        mapView.addAnnotation(annotation)
    }
    
    @IBAction func newCollectionButtonAction(_ sender: UIButton) {
        if selectedIndexes.count == 0 {
            
            // RESET photos array
            photos.removeAll()
            
            // REMOVE ALL PHOTOS FOR PIN
            selectedPin.removeFromPhotos(selectedPin.photos!)
            
            // GET NEW PHOTO SET FOR PIN
            getPhotosForPin()
        } else {
            deletePhotos()
            do {
                try stack.save()
            } catch {
                print("There was a problem saving")
            }
        }
        
        updateNewCollectionButton()
    }

    func getPhotosForPin() {
        FlickrClient.sharedInstance().photosForPin(pin: selectedPin, context: stack.mainContext) { (photos, error) in
            guard error == nil else {
                print("There was an error retrieving photos for pin")
                return
            }
            
            if let photos = photos {
                for photo in photos {
                    if (self.selectedPin == nil) {
                        fatalError("selectedPin is nil")
                    }
                    photo.pin = self.selectedPin
                }
                
                let queue = DispatchQueue(label: "myQueue")
                queue.async {
                    // placeholder
                    DispatchQueue.main.async {
                        self.photos = photos
                        do {
                            try self.stack.save()
                        } catch {
                            print("there was a problem saving photos")
                        }
                        self.collectionView.reloadData()
                        self.newCollectionButton.isEnabled = true
                    }
                }
            }
        }
    }
    
    func deletePhotos() {
        
        var photosToBeDeleted = [Photo]()
        
        collectionView.performBatchUpdates({
            // Build the phtoosToBDeleted array
            for indexPath in self.selectedIndexes {
                let photoObject = self.photos[indexPath.row]
                self.photos.remove(at: indexPath.row)
                self.collectionView.deleteItems(at: [indexPath])
                photosToBeDeleted.append(photoObject)
//                self.selectedPin.removeFromPhotos(photoObject)
            }
            }, completion: { (completed) in
                if self.photos.count == 0 {
                    let queue = DispatchQueue(label: "myQueue")
                    queue.async {
                        // placeholder
                        DispatchQueue.main.async {
                            self.stack.save()
                        }
                    }
                }
            })
        
        for photo in photosToBeDeleted {
            stack.mainContext.delete(photo)
        }
        
        selectedIndexes = [IndexPath]()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func updateNewCollectionButton() {
        
        if selectedIndexes.count > 0 {
            newCollectionButton.titleLabel?.text = "Delete"
        } else {
            newCollectionButton.titleLabel?.text = "New Collection"
        }
    }

    
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CollectionViewCell
        
        // TO DO: Configure the cell
        cell.backgroundColor = UIColor.gray

        //
        let photoObject = photos[indexPath.row]
        
        if let photoImage = photoObject.image {
            cell.imageView.image = photoImage
        } else {
            // TO DO: insert placeholder image
            cell.imageView.image = UIImage(named: "PlaceholderImage")
            
            cell.activityIndicator.startAnimating()
            cell.activityIndicator.isHidden = false
            
            FlickrClient.sharedInstance().getPhoto(photo: photos[indexPath.row]) { (imageData, error) in
                guard error == nil else {
                    print("Error")
                    return
                }
                
                let queue = DispatchQueue(label: "myQueue")
                queue.async {
                    // placeholder
                    DispatchQueue.main.async {
                        
                        cell.imageView.image = UIImage(data: imageData as! Data)
                        cell.activityIndicator.stopAnimating()
                        cell.activityIndicator.isHidden = true
                    }
                }
            }
        }
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CollectionViewCell
        if let index = selectedIndexes.index(of: indexPath) {
            selectedIndexes.remove(at: index)
            cell.imageView.alpha = 1.0
        } else {
            selectedIndexes.append(indexPath)
            cell.imageView.alpha = 0.1
        }
        
        updateNewCollectionButton()
    }

}

extension PhotoAlbumViewController: MKMapViewDelegate {
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
}
