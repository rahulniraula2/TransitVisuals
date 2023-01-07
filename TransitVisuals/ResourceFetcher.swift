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
    
    func loadBusStops(){
        let startTime = Date()
        
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL?
        let stopsUrl = documentsUrl?.appendingPathComponent("stops.txt")
        if let csvURL = stopsUrl {
            do{
                let csv = try CSV<Named>(url: csvURL)
                csv.rows.forEach({ row in
                    let busStop = MKPointAnnotation()
                    busStop.coordinate = CLLocationCoordinate2D(latitude: Double(row["stop_lat"]!) ?? 0.0, longitude: Double(row["stop_lon"]!) ?? 0.0)
                    busStop.title = "Bus Stop"
                    busStop.subtitle = row["stop_name"]!
                    //self.mapView.addAnnotation(busStop)
                    self.totalBusStops += 1
                })
            }catch{
                print("Error Loading Bus Stops")
            }
            
            
        }
        let tsf = String(format: "%3.0f", startTime.timeIntervalSinceNow * -1000.0)
        print("bus stops took: \(tsf)")
    }
    
    func loadTrips(service: String) -> (Set<String>, [String:[String]]){
        let startTime = Date()
        
        let documentsUrl2 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL?
        let tripsUrl = documentsUrl2?.appendingPathComponent("trips.txt")
        
        var shapes : Set = Set<String>()
        var tripShapes = [String:[String]]()
        
        if let csvURL = tripsUrl {
            do{
                let csv = try CSV<Named>(url: csvURL)
                csv.rows.forEach({ row in
                    if(row["service_id"]! == service){
                        self.tripName[row["trip_id"]!] = row["trip_headsign"]!
                        
                        if !self.tripNames.contains(row["trip_headsign"]!){
                            self.tripNames.append(row["trip_headsign"]!)
                        }
                        
                        shapes.insert(row["shape_id"]!)
                        
                        if tripShapes[row["shape_id"]!] == nil {
                            tripShapes[row["shape_id"]!] = []
                        }
                        
                        tripShapes[row["shape_id"]!]?.append(row["trip_id"]!)
                    }
                })
            } catch {
                print("Error Loading Trips")
            }
            
            
        }
        let tsf = String(format: "%3.0f", startTime.timeIntervalSinceNow * -1000.0)
        print("Found \(self.tripName.count) trips for today. took: \(tsf)")
        return (shapes, tripShapes)
        
    }
    
    func loadShapes(shapes : Set<String>, tripShapes : [String:[String]]){
        let startTime = Date()
        //let shapesToday = Array(tripShapes.values)
        var tripCLlocation = [String:[CLLocationCoordinate2D]]()
        let documentsUrl2 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL?
        let shapesURL = documentsUrl2?.appendingPathComponent("shapes.txt")
        if let csvURL = shapesURL {
            do{
                let csv = try CSV<Named>(url: csvURL)
                csv.rows.forEach({ row in
                    if(shapes.contains(row["shape_id"]!)){
                        if(tripCLlocation[row["shape_id"]!] == nil){
                            tripCLlocation[row["shape_id"]!]  = []
                        }
                        tripCLlocation[row["shape_id"]!]!.append(CLLocationCoordinate2D(latitude: Double(row["shape_pt_lat"]!)!, longitude: Double(row["shape_pt_lon"]!)!))
                    }
                })
            }catch {
                print("Error loading shapres")
            }
            
        }
        
        tripCLlocation.forEach { (key: String, value: [CLLocationCoordinate2D]) in
            let polyline = MKPolyline(coordinates: value, count: value.count)
            tripShapes[key]!.forEach { route in
                self.tripShape[route] = polyline
            }
        }
        
        let tsf = String(format: "%3.0f", startTime.timeIntervalSinceNow * -1000.0)
        print("Shapes took \(tsf)ms")
    }
    
    
    func initMap(){
        let loadingScreen = showLoadingScreen()
        let serviceID = getTodaysServiceID()
        loadBusStops()
        let shapes = loadTrips(service: serviceID)
        loadShapes(shapes: shapes.0, tripShapes: shapes.1)
        
        DispatchQueue.main.async {
            self.startTimer(20.0, repeats: true)
            self.centerMap()
            self.fetchDataVehiclePositions().resume()
            loadingScreen.dismiss(animated: true)
        }
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
