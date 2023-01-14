//
//  ServiceFetcher.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2023-01-13.
//

import Foundation
import SwiftCSV

class ServiceFetcher {
    static let shared = ServiceFetcher()
    var todaysServiceID : Int32? = nil
    
    func getServiceID() ->Int32{
        if let serviceID = todaysServiceID{
            return serviceID
        }else {
            var service = ""
            let startTime = Date()
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL?
            let calendarUrl = documentsUrl?.appendingPathComponent("calendar.txt")
            if let csvURL = calendarUrl {
                
                let todaysDate = Date().addingTimeInterval(TimeInterval(-180.0 * 60.0))
                let dateFormatter:DateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd"
                let todayString:String = dateFormatter.string(from: todaysDate)
                
                dateFormatter.dateFormat = "EEEE"
                let todayWeekDayString = dateFormatter.string(from: todaysDate).lowercased()
                
                do{
                    let csv = try CSV<Named>(url: csvURL)
                    for row in csv.rows{
                        if row["start_date"]! <= todayString && row["end_date"]! >= todayString &&  row[todayWeekDayString] == "1"{
                            service = row["service_id"]!
                            break
                        }
                    }
                }catch{
                    print("Error Getting today's service ID")
                }
            }
            
            let tsf = String(format: "%3.0f", startTime.timeIntervalSinceNow * -1000.0)
            print("Today's service_id = \(service) took: \(tsf)")
            return Int32(service)!
        }
    }
}
