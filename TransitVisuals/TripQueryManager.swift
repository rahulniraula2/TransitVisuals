//
//  TripQueryManager.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2023-01-11.
//

import CoreData
import UIKit

class TripQueryManager: DataQueryManager {
    static let shared = TripQueryManager()
    
    var trips = [Int32: Trips]()
    
    private static let pc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    let context = pc.newBackgroundContext()
    
    func getTrip(withID id: Int32) -> Trips? {
        if let trip = trips[id] {
            return trip
        }else {
            return self.queryTrips(withIDs: [id]).first
        }
    }
    
    func getTrips(withIDs ids: [Int32]){
        let idToQuery = ids.filter { id in
            return !self.trips.keys.contains(where: { key in
                return key == id
            })
        }
        var newTrips : [Trips] = []
        if !idToQuery.isEmpty {
            newTrips = queryTrips(withIDs: idToQuery)
        }
        for trip in newTrips {
            self.trips[trip.trip_id] = trip
        }
    }
    
    
    func queryTrips(withIDs ids: [Int32] = []) -> [Trips]{
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
