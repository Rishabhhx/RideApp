//
//  ViewController.swift
//  RideApp
//
//  Created by Rishabh Sharma on 11/09/24.
//

import UIKit
import MapKit
import CoreLocation

class HomeVC: UIViewController {
    
    // MARK: Outlets
    @IBOutlet private weak var mapView: MKMapView!
    
    // MARK: Properties
    private var viewModel = HomeViewModel()
    
    // MARK: Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        initialzeSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presentPopup()
    }
    
    // MARK: Private Functions
    private func initialzeSetup() {
        viewModel.delegate = self
        mapView.delegate = self
        mapView.showsUserLocation = true
    }
    
    // setting up location
    private func determineCurrentLocation() {
        viewModel.locationManager.delegate = self
        viewModel.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        viewModel.locationManager.distanceFilter = 50
        viewModel.checkLocationAuthorization()
    }
    
    // adding route polyline to map
    private func addPolylineOverlay() {
        addAnnotations()
        
        let directionRequest = viewModel.createDirectionRequest()
        let direction = MKDirections(request: directionRequest)

        direction.calculate { (response, error) in
            guard let response = response else {
                if let error = error {
                    print("ERROR FOUND : \(error.localizedDescription)")
                }
                return
            }
            let route = response.routes[0]
            let overLay: MKOverlay = route.polyline
            self.mapView.addOverlay(overLay, level: MKOverlayLevel.aboveRoads)
            if let removeOverlay = self.viewModel.overlayShown {
                self.mapView.removeOverlay(removeOverlay)
            }
            self.viewModel.overlayShown = overLay
            let center = route.polyline.coordinate
            let mRegion = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06))
            self.mapView.setRegion(mRegion, animated: true)
        }
    }
    
    // adding annotations to map
    private func addAnnotations() {
        let riderLocationPlaceMark = MKPlacemark(coordinate: viewModel.riderLocation, addressDictionary: nil)
        let riderLocationAnnotation = MKPointAnnotation()
        riderLocationAnnotation.title = "Bike"
        
        if let location = riderLocationPlaceMark.location {
            riderLocationAnnotation.coordinate = location.coordinate
        }
        if let existingAnnotation = self.mapView.annotations.first(where: { $0.title == "Bike" }) as? MKPointAnnotation {
            
            // adding animation so that it looks smooth when driver location is updated
            UIView.animate(withDuration: 1.0, animations: {
                existingAnnotation.coordinate = riderLocationAnnotation.coordinate
            })
        } else {
            self.mapView.addAnnotation(riderLocationAnnotation)
        }
    }
    
    // presenting popup view
    private func presentPopup() {
        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "StartRidePopupVC") as? StartRidePopupVC {
            viewController.popupDelegate = self
            viewController.modalPresentationStyle = .overFullScreen
            self.present(viewController, animated: true)
            resetDriverLocation()
        } else {
            print("Error: Could not instantiate StartRidePopupVC")
        }
    }
    
    // resetting the location
    private func resetDriverLocation() {
        let lat = viewModel.userLocation.coordinate.latitude
        let long = viewModel.userLocation.coordinate.longitude
        viewModel.destination = CLLocationCoordinate2D(latitude: lat, longitude: long)
        viewModel.riderLocation = CLLocationCoordinate2D(latitude: lat + 0.050022, longitude: long + 0.050022)
    }
}

// MARK: Delegates
extension HomeVC: HomeViewModelProtocol {
    func startUpdatingRiderPosition() {
        viewModel.riderTimer?.invalidate()
        viewModel.riderTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) {_ in
            self.addPolylineOverlay()
            if self.viewModel.riderLocation.latitude <= self.viewModel.userLocation.coordinate.latitude || self.viewModel.riderLocation.longitude <= self.viewModel.userLocation.coordinate.longitude {
                self.viewModel.riderTimer?.invalidate()
                self.presentPopup()
            }
        }
    }
    
    func presentPopupAgain() {
        presentPopup()
    }
}

extension HomeVC: PopupProtocol {
    func startRide() {
        determineCurrentLocation()
    }
}

// MARK: Map Delegate
extension HomeVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let rendere = MKPolylineRenderer(overlay: overlay)
        rendere.lineWidth = 5
        rendere.strokeColor = .systemBlue
        return rendere
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Bike")
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Bike")
        } else {
            annotationView?.annotation = annotation
        }
        switch annotation.title {
        case "Bike":
            if let image = UIImage(named: "Bike") {
                let image = image.resizeImage(targetSize: CGSize(width: 60, height: 60))
                annotationView?.image = image
            }
        default:
            break
        }
        return annotationView
    }
}


// MARK: Location Delegate
extension HomeVC: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        viewModel.userLocation = locations[0] as CLLocation
        let lat = viewModel.userLocation.coordinate.latitude
        let long = viewModel.userLocation.coordinate.longitude
        viewModel.destination = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        // manually setting driver location to near userl ocation
        viewModel.riderLocation = CLLocationCoordinate2D(latitude: lat + 0.050022, longitude: long + 0.050022)
        addPolylineOverlay()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error - locationManager: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        viewModel.checkLocationAuthorization()
    }
}
