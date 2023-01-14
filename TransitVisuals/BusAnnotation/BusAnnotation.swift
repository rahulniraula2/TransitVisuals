//
//  BusAnnotation.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2022-08-10.
//

import Foundation
import UIKit
import MapKit

class BusPointAnnotation: MKPointAnnotation {
    @objc dynamic var bearing: CGFloat = 0.0
    @objc dynamic var tripID: Int32 = 0
    @objc dynamic var shapeID: Int32 = 0
    @objc dynamic var determined: Bool = false
    @objc dynamic var correctlyDetermined: Bool = false
    @objc dynamic var isObserved: Bool = false
    
    func configureAnnotation(to vehicle: TransitRealtime_VehiclePosition){
        
        let location = CLLocationCoordinate2D(latitude: CLLocationDegrees(vehicle.position.latitude), longitude: CLLocationDegrees(vehicle.position.longitude))
        
        //let trip_id = Int32(vehicle.trip.tripID) ?? -1
        
        /*if let trip = TripQueryManager.shared.getTrip(withID: trip_id) {
            if(!self.determined){
                self.title = trip.trip_headsign
                self.tripID = Int32(vehicle.trip.tripID) ?? -1
                self.shapeID = trip.shape_id
                self.updateSubtitle(tripMessage: tripMessage)
            }
        }*/
        self.bearing = CGFloat(vehicle.position.bearing - 90).inRadians()
        UIView.animate(withDuration: 1){
            self.coordinate = location
        }
    }
    
    func updateTrip(trip: Trips?, determined: Bool, correctlyDetermined: Bool){
        self.determined = determined
        self.subtitle = "THIS BUS TRIP WAS DETERMINED"
        if let trip = trip {
            self.correctlyDetermined = correctlyDetermined
            self.title = trip.trip_headsign
            self.shapeID = trip.shape_id
            self.tripID = trip.trip_id
        }else{
            self.title = "NA"
            self.shapeID = -1
            self.tripID = -1
        }
    }
    
    func updateSubtitle(tripMessage: String?) {
        if let tripMessage = tripMessage {
            self.subtitle = tripMessage
        }else {
            self.subtitle =  "No updates for this trip"
        }
    }
}

class BusAnnotation: UIView {
   
    @IBOutlet weak var busIcon: UIImageView!
    @IBOutlet weak var busNumberLabel: UILabel!
    @IBOutlet weak var backgroundLayer: UIView!
    @IBOutlet weak var triangle: UIImageView!
    
    @IBOutlet weak var xConstraint: NSLayoutConstraint!
    @IBOutlet weak var yConstraint: NSLayoutConstraint!
    
    var kvoToken: NSKeyValueObservation?
    var kvoTokenTitle: NSKeyValueObservation?
    
    static func getNewBusAnnotation(for mapView: MKMapView, with annotation: BusPointAnnotation) -> MKAnnotationView?{
        
        let nibName = "BusAnnotation"
        let reuseIdentifier = "EmptyVehicle"
        var annotationView: MKAnnotationView?
        let viewFromNib = Bundle.main.loadNibNamed(nibName, owner: self, options: nil)?.first as! BusAnnotation
        
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) {
            if dequeuedAnnotationView.subviews.isEmpty {
                dequeuedAnnotationView.addSubview(viewFromNib)
            }
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        } else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView?.addSubview(viewFromNib)
        }
         
        annotationView?.layer.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        annotationView?.canShowCallout = true
        annotationView?.displayPriority = .required
        
        let customView = annotationView!.subviews.first as? BusAnnotation
        customView?.frame = annotationView!.frame
        
        customView?.configureAnnotation(to: annotation)
        
        return annotationView
    }
    
    func observe(_ annotation: BusPointAnnotation) {
        self.kvoToken = annotation.observe(\.tripID, options: .new, changeHandler: { [weak self] observedAnotation, change in
            if change.newValue != nil {
                DispatchQueue.main.async {
                    self?.configureAnnotation(to: observedAnotation)
                }
            }
        })
    }
    
    deinit {
        kvoToken?.invalidate()
        kvoTokenTitle?.invalidate()
    }
    
    func rotateTriangle(_ bearing: CGFloat){
        //DispatchQueue.main.async {
            UIView.animate(withDuration: 1){
                let xOffSet: CGFloat = CGFloat(cos(bearing) * 16.5)
                let yOffSet: CGFloat = CGFloat(sin(bearing) * 16.5)
                self.xConstraint.constant = xOffSet
                self.yConstraint.constant = yOffSet
                self.triangle.transform = .identity
                self.triangle.transform = (self.triangle.transform.rotated(by: CGFloat(bearing + .pi/2)))
                self.layoutIfNeeded()
            }
        //}
    }
    
    func configureAnnotation(to annotation: BusPointAnnotation){
        let title = extractBusNumber(annotation.title ?? "")
        self.busNumberLabel.text = title
        self.backgroundLayer.layer.cornerRadius = (self.backgroundLayer.frame.size.width) / 2
        self.backgroundLayer.layer.borderWidth = 2
        self.backgroundLayer.layer.borderColor = #colorLiteral(red: 0.01372012775, green: 0.4772869349, blue: 0.9992420077, alpha: 1).cgColor
        
        if(annotation.correctlyDetermined){
            self.busNumberLabel.textColor = .blue
        }else{
            self.busNumberLabel.textColor = .red
        }
        self.rotateTriangle(annotation.bearing)
        self.observe(annotation)
        
    }
    
    
    private func extractBusNumber(_ title: String?) -> String{
        if let title = title {
            let title_prefix = String(title.prefix(3))
            var returnString = ""
            var found = false
            title_prefix.forEach { Character in
                if !Character.isWhitespace{
                    if(!found){
                        returnString.append(Character)
                    }
                }else{
                    found = true
                }
            }
            return returnString
        }
        return ""
    }
    
    
}



