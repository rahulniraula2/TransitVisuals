//
//  DataManagerIntitializer.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2023-01-06.
//
import UIKit
import CoreData
import SwiftCSV

class DataMangagerInitializer {
    private let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private let pc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    static let shared = DataMangagerInitializer()
    
    func initializeDataBase(){
        debugPrint(documentsUrl)
        DispatchQueue.global(qos: .userInteractive).async {
            let entities = K.CoreData.Entities.all
            for entity in entities {
                self.deleteAllEntity(entity)
            }
            self.initAll()
        }
    }
    
    func initAll() {
        initRoutes()
        initShapes()
        initStops()
        initStopTimes()
        initTrips()
    }
    
    func initRoutes() {
        let fileName = "routes.txt"
        let csv = getCSV(fileName)
        enumerateCSV(csv, fileName : fileName) { dist, context in
            let route = Routes(context: context)
            route.route_id = Int32(dist["route_id"]!)!
            route.route_color = dist["route_color"]!
            route.route_desc = dist["route_desc"]!
            route.route_long_name = dist["route_long_name"]!
            route.route_short_name = Int32(dist["route_short_name"]!)!
        }
    }
    
    func initShapes() {
        let fileName = "shapes.txt"
        let csv = getCSV(fileName)
        enumerateCSV(csv, fileName : fileName) { dist, context in
            let shape = Shapes(context: context)
            shape.shape_id = Int32(dist["shape_id"]!)!
            shape.shape_pt_lat = Double(dist["shape_pt_lat"]!)!
            shape.shape_pt_lon = Double(dist["shape_pt_lon"]!)!
            shape.shape_pt_sequence = Int16(dist["shape_pt_sequence"]!)!
        }
    }
    
    func initStops() {
        let fileName = "stops.txt"
        let csv = getCSV(fileName)
        enumerateCSV(csv, fileName : fileName) { dist, context in
            let stop = Stops(context: context)
            stop.stop_code = Int32(dist["stop_code"]!)!
            stop.stop_id = Int32(dist["stop_id"]!)!
            stop.stop_name = dist["stop_name"]
            stop.stop_lat = Double(dist["stop_lat"]!)!
            stop.stop_lon = Double(dist["stop_lon"]!)!
        }
    }
    
    func initStopTimes() {
        let fileName = "stop_times.txt"
        let csv = getCSV(fileName)
        enumerateCSV(csv, fileName : fileName) { dist, context in
            let stopTime = StopTimes(context: context)
            stopTime.trip_id = Int32(dist["trip_id"]!)!
            stopTime.stop_id = Int32(dist["stop_id"]!)!
            stopTime.stop_sequence = Int16(dist["stop_sequence"]!)!
            stopTime.arrival_time = dist["arrival_time"]!
            stopTime.departure_time = dist["departure_time"]!
            stopTime.stop_headsign = dist["stop_headsign"]!
        }
    }
    
    func initTrips() {
        let fileName = "trips.txt"
        let csv = getCSV(fileName)
        enumerateCSV(csv, fileName : fileName) { dist, context in
            let trip = Trips(context: context)
            trip.trip_id = Int32(dist["trip_id"]!)!
            trip.shape_id = Int32(dist["shape_id"]!)!
            trip.service_id = Int32(dist["service_id"]!)!
            trip.route_id = Int32(dist["route_id"]!)!
            trip.block_id = Int32(dist["block_id"]!)!
            trip.trip_headsign = dist["trip_headsign"]!
            trip.direction_id = dist["direction_id"]! == "1"
        }
    }
    
    private func enumerateCSV(_ csv : CSV<Enumerated>, fileName : String, _ handler: @escaping ([String : String], _ context: NSManagedObjectContext) -> Void) {
        pc.performBackgroundTask { context in
            let time = Date()
            var i = 0
            do{
                try csv.enumerateAsDict({ dist in
                    handler(dist, context)
                    i = i + 1
                    if(i % 10000 == 0){
                        self.saveContext(context: context)
                    }
                })
            }catch{
                debugPrint("Error Adding data for \(fileName)")
            }
            self.saveContext(context: context)
            self.printTime(since: time, task: "Loading \(fileName)")
        }
    }
    
    private func getCSV(_ fileName: String) -> CSV<Enumerated> {
        var csv : CSV<Enumerated>? = nil
        let fileURL = documentsUrl.appendingPathComponent(fileName)
        do{
            csv = try CSV<Enumerated>(url: fileURL, delimiter: .comma, loadColumns: false)
        }catch{
            debugPrint("Error Loading File \(fileName)")
        }
        return csv!
    }
    
    private func deleteAllEntity(_ entityName : String) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        self.pc.performBackgroundTask { context in
            let date = Date()
            do {
                let items = try context.fetch(request)
                for item in items {
                    context.delete(item as! NSManagedObject)
                }
                self.saveContext(context: context)
            }
            catch {
                debugPrint("Error Fetching data from context. \(error)")
            }
            self.printTime(since: date, task: "Deleting \(entityName) database")
            /*if(entityName == K.CoreData.Entities.Trips){
                self.initTrips()
            } else if(entityName == K.CoreData.Entities.StopTimes){
                self.initStopTimes()
            } else if(entityName == K.CoreData.Entities.Shapes){
                self.initShapes()
            } else if(entityName == K.CoreData.Entities.Routes){
                self.initRoutes()
            } else if(entityName == K.CoreData.Entities.Stops){
                self.initStops()
            }*/
        }
    }
    
    private func saveItems(){
        self.saveContext(context: self.context)
    }
    
    private func saveContext(context: NSManagedObjectContext){
        do{
            try context.save()
        }
        catch {
            debugPrint("Error Saving \(error)")
        }
    }
    
    private func printTime(since startTime: Date, task : String){
        let tsf = String(format: "%3.0f", startTime.timeIntervalSinceNow * -1000.0)
        debugPrint("\(task) Took: \(tsf)")
    }
    
}
