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
    
    private static let pc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    let context = pc.newBackgroundContext()
    
    func getBusStop(withID id: Int32) async -> BusStopAnnotation {
        if let stop = self.busStops[id] {
            return stop
        }else {
            let stop = await queryBusStops(withIDs: [id]).first!
            let stopAnnotation = DataConverters.getBusStopAnnotation(stop)
            self.busStops[id] = stopAnnotation
            return stopAnnotation
        }
    }
    
    func getAllBusStops(in mapRegion: MKCoordinateRegion) async -> [BusStopAnnotation]{
        let stops = await queryBusStops(in : mapRegion)
        var returnAnnotation : [BusStopAnnotation] = []
        
        for stop in stops {
            if let stop = self.busStops[stop.stop_id] {
                returnAnnotation.append(stop)
            }else{
                let annot = DataConverters.getBusStopAnnotation(stop)
                self.busStops[stop.stop_id] = annot
                returnAnnotation.append(annot)
            }
        }
        
        return returnAnnotation
    }
    
    private func queryBusStops(withIDs ids: [Int32] = [], in mapRegion: MKCoordinateRegion? = nil) async -> [Stops]{
        
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
