//
//  BusStopQueryManager.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2023-01-11.
//

import UIKit
import CoreData
import UIKit
import MapKit

class BusStopQueryManager : DataQueryManager {
    
    static let shared = BusStopQueryManager()
    
    var busStops = [Int32: BusStopAnnotation]()
    var stops = [Int32: Stops]()
    
    func getBusStop(withID id: Int32) -> BusStopAnnotation {
        if let stop = self.busStops[id] {
            return stop
        }else {
            let stop = queryBusStops(withIDs: [id]).first!
            let stopAnnotation = DataConverters.getBusStopAnnotation(stop)
            self.busStops[id] = stopAnnotation
            return stopAnnotation
        }
    }
    
    func getStop(withID id: Int32) -> Stops {
        if let stop = self.stops[id] {
            return stop
        }else{
            let stop = queryBusStops(withIDs: [id]).first!
            self.stops[id] = stop
            return stop
        }
    }
    
    func getAllBusStops(in mapRegion: MKCoordinateRegion) -> [BusStopAnnotation]{
        let stops = queryBusStops(in : mapRegion)
        var returnAnnotation : [BusStopAnnotation] = []
        
        for stop in stops {
            if let stop = self.busStops[stop.stop_id] {
                returnAnnotation.append(stop)
            }else{
                let annot = DataConverters.getBusStopAnnotation(stop)
                self.busStops[stop.stop_id] = annot
                self.stops[stop.stop_id] = stop
                returnAnnotation.append(annot)
            }
        }
        
        return returnAnnotation
    }
    
    private func queryBusStops(withIDs ids: [Int32] = [], in mapRegion: MKCoordinateRegion? = nil) -> [Stops]{
        
        let fReq: NSFetchRequest<Stops> = Stops.fetchRequest()
        
        if !ids.isEmpty{
            fReq.predicate = NSPredicate(format: "stop_id IN %@", ids)
        }
        
        if let mapRegion = mapRegion {
            fReq.predicate = NSPredicate(format: "stop_lat BETWEEN {%lf, %lf} AND stop_lon BETWEEN {%lf, %lf}", getStartingLatitude(mapRegion), getEndingLatitude(mapRegion), getStartingLongitude(mapRegion), getEndingLongitude(mapRegion))
        }
        
        do{
            let busStopsArr = try context.fetch(fReq)
            
            return busStopsArr
        }catch{
            print("Error Fetching Bus Stops")
        }
        return []
    }
    
    private func getStartingLatitude(_ mapRegion: MKCoordinateRegion) -> Double {
        return mapRegion.center.latitude - (mapRegion.span.latitudeDelta / 2)
    }
    
    private func getEndingLatitude(_ mapRegion: MKCoordinateRegion) -> Double {
        return mapRegion.center.latitude + (mapRegion.span.latitudeDelta / 2)
    }
    
    private func getStartingLongitude(_ mapRegion: MKCoordinateRegion) -> Double {
        return mapRegion.center.longitude - (mapRegion.span.latitudeDelta / 2)
    }
    
    private func getEndingLongitude(_ mapRegion: MKCoordinateRegion) -> Double {
        return mapRegion.center.longitude + (mapRegion.span.latitudeDelta / 2)
    }
    
}
