//
//  StopTimesQueryManager.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2023-01-13.
//

import Foundation
import CoreData

class StopTimesQueryManager : DataQueryManager {
    
    static let shared = StopTimesQueryManager()
    
    let timeSpan = 15
    
    func queryAllCurrentTrips(tripIDs ids: [Int32]) -> [StopTimes]{
        let context = RouteShapeQueryManager.pc.viewContext
        
        let fReq: NSFetchRequest<StopTimes> = StopTimes.fetchRequest()
        
        let (timestamp, timestamp2) = getTimeStamps()
        
        let predicate = NSPredicate(format: "(trip_id IN %@) AND arrival_time >= %@ AND arrival_time <= %@", ids, timestamp, timestamp2)
        fReq.predicate = predicate

        do{
            return try context.fetch(fReq)
            
        }catch{
            print("Error getting trips")
        }
        
        return []
    }
    
    private func getTimeStamps() -> (String, String){
        let date = Date()
        let calendar = Calendar.current
        let minutesToAdd = self.timeSpan
        
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
        
        return (timestamp,timestamp2)
    }
}
