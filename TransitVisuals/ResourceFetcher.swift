//
//  ResourceFetcher.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2022-08-10.
//

import UIKit
import MapKit
import SwiftProtobuf
import SwiftCSV
import ZIPFoundation

extension ViewController {
    
    func getTodaysServiceID() -> String{
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
        return service
    }
    
    func showLoadingScreen() -> UIAlertController{
        let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating();
        alert.view.addSubview(loadingIndicator)
        DispatchQueue.main.async {
            self.present(alert, animated: false)
        }
        return alert
    }
    
}
