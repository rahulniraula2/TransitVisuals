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
    static let pc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    let context = pc.newBackgroundContext()
    
    static func getAllTrips(forServiceID id: String) -> [Trips]{
        let context = RouteShapeQueryManager.pc.viewContext
        
        let fReq: NSFetchRequest<Trips> = Trips.fetchRequest()
        
        let id_int = Int32(id)!
        fReq.predicate = NSPredicate(format: "service_id == %d", id_int)
        
        do{
            return try context.fetch(fReq)
            
        }catch{
            print("Error getting trips")
        }
        
        return []
    }
    
    static func getTrip(forShapeID id: Int32) -> Trips?{
        let context = RouteShapeQueryManager.pc.viewContext
        
        let fReq: NSFetchRequest<Trips> = Trips.fetchRequest()
        
        let id_int = id
        fReq.predicate = NSPredicate(format: "shape_id == %d", id_int)
        fReq.fetchLimit = 1
        
        do{
            return try context.fetch(fReq).first
            
        }catch{
            print("Error getting trips")
        }
        return nil
    }
    
    static func filterForAfterMidnight(tripIDs ids: [Int32]) -> [StopTimes]{
        let context = RouteShapeQueryManager.pc.viewContext
        
        let fReq: NSFetchRequest<StopTimes> = StopTimes.fetchRequest()
        
        let date = Date()
        let calendar = Calendar.current
        let minutesToAdd = 15
        
        let newDate1 = calendar.date(byAdding: .minute, value: -1*minutesToAdd, to: date)
        let newDate2 = calendar.date(byAdding: .minute, value: minutesToAdd, to: date)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        var currentHour = Calendar.current.component(.hour, from: newDate1!)
        var timestamp = formatter.string(from: newDate1!)
        if(currentHour < 3){
            var array = Array(timestamp)
            array[0] = "2"
            array[1] = currentHour == 0 ? "4" : "5"
            timestamp = String(array)
        }
        var timestamp2 = formatter.string(from: newDate2!)
        currentHour = Calendar.current.component(.hour, from: newDate2!)
        if(currentHour < 3){
            var array = Array(timestamp2)
            array[0] = "2"
            array[1] = currentHour == 0 ? "4" : "5"
            timestamp2 = String(array)
        }
        
        let predicate = NSPredicate(format: "(trip_id IN %@) AND arrival_time >= %@ AND arrival_time <= %@", ids, timestamp, timestamp2)
        //print(predicate.description)
        fReq.predicate = predicate

        do{
            return try context.fetch(fReq)
            
        }catch{
            print("Error getting trips")
        }
        
        return []
    }
}
