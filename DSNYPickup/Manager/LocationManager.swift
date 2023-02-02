//
//  LocationManager.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/21/23.
//

import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject {
    @Published var location: CLLocation?
    @Published var region: MKCoordinateRegion = MKCoordinateRegion.defaultRegion()
    @Published var invalid: Bool = false
    private let locationManager = CLLocationManager()
    lazy var geocoder = CLGeocoder()

    override init() {
        super.init()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
    }
      
    func openMapWithAddress(location: String) {
           geocoder.geocodeAddressString(location) { placemarks, error in
               if let error = error {
                   DispatchQueue.main.async {
                       self.invalid = true
                   }
                   print(error.localizedDescription)
               }
               
               guard let placemark = placemarks?.first else {
                   return
               }
               
               guard let lat = placemark.location?.coordinate.latitude else{return}
               
               guard let lon = placemark.location?.coordinate.longitude else{return}
               
               let coords = CLLocationCoordinate2DMake(lat, lon)
               
               let place = MKPlacemark(coordinate: coords)
               
               let mapItem = MKMapItem(placemark: place)
               mapItem.name = location
               mapItem.openInMaps(launchOptions: nil)
           }
           
       }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async { [weak self] in
            self?.location = location
            self?.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
        }
    }
}


extension MKCoordinateRegion {
    static func defaultRegion () -> MKCoordinateRegion {
        MKCoordinateRegion(center: CLLocationCoordinate2D.init(latitude: 40.7484, longitude: 73.9857),
                           latitudinalMeters: 100, longitudinalMeters: 100)
    }
}
