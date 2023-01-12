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
    @objc dynamic var tripID: String = ""
    @objc dynamic var shapeID: Int32 = 0
    
    func configureAnnotation(to entity_data: TransitRealtime_FeedEntity, tripMessage: String?){
        self.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(entity_data.vehicle.position.latitude), longitude: CLLocationDegrees(entity_data.vehicle.position.longitude))
        let trip_id = Int32(entity_data.vehicle.trip.tripID) ?? -1
        
        if let trip = TripQueryManager.shared.getTrip(withID: trip_id) {
            self.title = trip.trip_headsign
            self.tripID = entity_data.vehicle.trip.tripID
            self.shapeID = trip.shape_id
            self.updateSubtitle(tripMessage: tripMessage)
        }
        self.bearing = CGFloat(entity_data.vehicle.position.bearing - 90).inRadians()
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
    
    func observe(_ annotation: BusPointAnnotation) {
        //if let annotation = annotation{
        self.kvoToken = annotation.observe(\.bearing, options: .new, changeHandler: { observedAnotation, change in
                if let newVal = change.newValue {
                    self.rotateTriangle(newVal)
                }
            })
        //}
    }
    
    deinit {
            kvoToken?.invalidate()
    }
    
    func rotateTriangle(_ bearing: CGFloat){
        let xOffSet: CGFloat = CGFloat(cos(bearing) * 16.5)
        let yOffSet: CGFloat = CGFloat(sin(bearing) * 16.5)
        self.xConstraint.constant = xOffSet
        self.yConstraint.constant = yOffSet
        self.triangle.transform = .identity
        self.triangle.transform = (self.triangle.transform.rotated(by: CGFloat(bearing + .pi/2)))
        DispatchQueue.main.async {
            self.layoutIfNeeded()
        }
    }
    
    
}



