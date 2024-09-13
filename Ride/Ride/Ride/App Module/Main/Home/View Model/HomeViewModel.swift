//
//  HomeViewModel.swift
//  RideApp
//
//  Created by Rishabh Sharma on 11/09/24.
//

import UIKit
import MapKit
import CoreLocation

protocol HomeViewModelProtocol : AnyObject {
    func startUpdatingRiderPosition()
    func presentPopupAgain()
}

class HomeViewModel {
    
    // MARK: Properties
    var locationManager: CLLocationManager = CLLocationManager()
    var userLocation:CLLocation = CLLocation()
    var destination = CLLocationCoordinate2D()
    var riderLocation = CLLocationCoordinate2D()
    var overlayShown: MKOverlay?
    var timer: Timer?
    var riderTimer: Timer?
    weak var delegate: HomeViewModelProtocol?

    // MARK: Private Methods
    func checkLocationAuthorization(){
        switch locationManager.authorizationStatus{
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted:
            print("restricted")
        case .denied:
            print("denied")
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            startUpdatingRiderLocation()
            delegate?.startUpdatingRiderPosition()
        default:
            break
        }
    }
    
    // manually updating driver location every 1 sec.
    func startUpdatingRiderLocation() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.riderLocation.latitude <= self.userLocation.coordinate.latitude || self.riderLocation.longitude <= self.userLocation.coordinate.longitude {
                self.timer?.invalidate()
                self.delegate?.presentPopupAgain()
            }
            self.updateLocation()
        }
    }
    
    func updateLocation() {
        riderLocation = CLLocationCoordinate2D(latitude: riderLocation.latitude - 0.000600, longitude: riderLocation.longitude - 0.000600)
    }
    
    // converting location cords. to a direction for our polyline
    func createDirectionRequest() -> MKDirections.Request {
        let sourcePlaceMark = MKPlacemark(coordinate: destination, addressDictionary: nil)
        let destinationPlaceMark = MKPlacemark(coordinate: riderLocation, addressDictionary: nil)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlaceMark)
        let destinationItem = MKMapItem(placemark: destinationPlaceMark)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationItem
        directionRequest.transportType = .automobile
        return directionRequest
    }
}
