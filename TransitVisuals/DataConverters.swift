//
//  DataConverters.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2023-01-08.
//

import Foundation
import UIKit
import MapKit
import CoreData

class DataConverters{
    
    static func getBusStopAnnotation(_ stop: Stops) -> BusStopAnnotation {
        let busStop = BusStopAnnotation()
        //let coordinate = generateRandomCoordinates()
        let lon = stop.stop_lon//CLLocationDegrees(Double(round(1000000 * stop.stop_lon) / 1000000))
        let lat = stop.stop_lat//CLLocationDegrees(Double(round(1000000 * stop.stop_lat) / 1000000))
        //busStop.coordinate = coordinate
        busStop.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        busStop.stop_id = stop.stop_id
        busStop.title = stop.stop_name
        busStop.subtitle = stop.stop_code.description
        return busStop
    }
    
    static func getBusStopAnnotation(_ stops: [Stops]) -> [BusStopAnnotation] {
        var stopAnnotations : [BusStopAnnotation] = []
        for stop in stops {
            stopAnnotations.append(self.getBusStopAnnotation(stop))
        }
        return stopAnnotations
    }
    
    
    
    static func generateRandomCoordinates() -> CLLocationCoordinate2D {
        let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(randomBetweenNumbers(-90, secondNum: 90)), longitude: CLLocationDegrees(randomBetweenNumbers(-180, secondNum: 180)))
        
        return coordinate
    }

    static func randomBetweenNumbers(_ firstNum: CGFloat, secondNum: CGFloat) -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
}
