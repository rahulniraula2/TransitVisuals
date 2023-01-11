//
//  DataQueryManager.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2023-01-08.
//

import Foundation
import UIKit
import CoreData
import UIKit
import MapKit

class DataQueryManager {
    
}

class BusStopQueryManager : DataQueryManager {
    
    static let shared = BusStopQueryManager()
    
    var busStops = [Int32: BusStopAnnotation]()
    
    private let pc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    
    func getAllBusStopAsAnnotation() async -> [MKPointAnnotation] {
        let allBusStops = await self.getAllBusStops()
        let busAnnotations = DataConverters.getBusStopAnnotation(allBusStops)
        loadBusStopsToGlobalFunction(stops: busAnnotations)
        return busAnnotations
    }
    
    func loadBusStopsToGlobalFunction(stops: [MKPointAnnotation]){
        DispatchQueue.global(qos: .background).async {
            for stop in stops {
                if let stop = stop as? BusStopAnnotation {
                    self.busStops[stop.stop_id] = stop
                }
            }
        }
    }
    
    func getAllBusStops() async -> [Stops] {
        return await self.queryBusStops()
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
        let context = pc.newBackgroundContext()
        
        let fReq: NSFetchRequest<Stops> = Stops.fetchRequest()
        
        if !ids.isEmpty{
            
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
        return mapRegion.center.latitude - mapRegion.span.latitudeDelta
    }
    
    private func getEndingLatitude(_ mapRegion: MKCoordinateRegion) -> Double {
        return mapRegion.center.latitude + mapRegion.span.latitudeDelta
    }
    
    private func getStartingLongitude(_ mapRegion: MKCoordinateRegion) -> Double {
        return mapRegion.center.longitude - mapRegion.span.latitudeDelta
    }
    
    private func getEndingLongitude(_ mapRegion: MKCoordinateRegion) -> Double {
        return mapRegion.center.longitude + mapRegion.span.latitudeDelta
    }
    
}

class TripQueryManager: DataQueryManager {
    static let shared = TripQueryManager()
    
    var trips = [Int32: Trips]()
    
    private let pc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    
    
    func queryTrips(withIDs ids: [Int32] = []) -> [Trips]{
        let context = pc.viewContext
        
        let fReq: NSFetchRequest<Trips> = Trips.fetchRequest()
        
        if !ids.isEmpty{
            fReq.predicate = NSPredicate(format: "trip_id IN %@", ids)
        }
        
        do{
            return try context.fetch(fReq)
        }catch{
            print("Error Fetching Bus Stops")
        }
        return []
    }
}
