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
    //MARK: - Bus Stop Annotation
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
    
    //MARK: - Bus Trip Polyline Overlay
    
    static func getRouteOverlay(_ coordinates: [CLLocationCoordinate2D]) -> MKPolyline {
        
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        
        return polyline
    }
}
