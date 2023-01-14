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
    
    //MARK: - Global Variables
    private let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static let shared = DataMangagerInitializer()
    
    /// CoreData
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private let pc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    
    /// Serial Queues. Helps with concurent processes with safe data access
    private let serialQueue = DispatchQueue(label: "TaskNotification.DataManagerInitializer", qos: .userInitiated)
    private let progressQueue = DispatchQueue(label: "ProgressUpdater.DataManagerInitializer", qos: .default)
    
    /// Progress Checker Variables
    private var TasksDelete : [String:Bool] = [:]
    private var TasksAdd : [String:Bool] = [:]
    private var totalStopTimeThreads = -1
    private var totalStopTimeThreadsCompleted = 0
    private var totalCompletedForNotification = 0.0
    
    /// External Delegate
    var delegate : DataMangagerInitializerDelegate? = nil
    
    //MARK: - Public Methods
    
    init(){
        self.initializeTaskCompletionData()
    }
    
    func initializeDataBase(){
        print(documentsUrl)
        self.initializeTaskCompletionData()
        
        DispatchQueue.global(qos: .default).async {
            self.deleteAllEntities()
            self.loadAll()
        }
    }
    
    func deleteAllEntities(){
        let entities = K.CoreData.Entities.all
        for entity in entities {
            self.deleteAllEntity(entity)
        }
    }
    
    func loadOnly(){
        self.loadAll()
    }
    
    //MARK: - Database loading helpers
    
    private func loadAll() {
        DispatchQueue.global(qos: .background).async {
            self.loadRoutes()
        }
        DispatchQueue.global(qos: .default).async {
            self.loadShapes()
        }
        DispatchQueue.global(qos: .background).async {
            self.loadStops()
        }
        DispatchQueue.global(qos: .userInteractive).async {
            self.concurentLoadStopTime()
        }
        DispatchQueue.global(qos: .background).async {
            self.loadTrips()
        }
    }
    
    private func loadRoutes() {
        let fileName = "routes.txt"
        let csv = getCSV(fileName)
        self.updateProgress(value: 18)
        enumerateCSV(csv, entityName: K.CoreData.Entities.Routes, progressWeight: 567 ) { dist, context in
            let route = Routes(context: context)
            route.route_id = Int32(dist["route_id"]!)!
            route.route_color = dist["route_color"]!
            route.route_desc = dist["route_desc"]!
            route.route_long_name = dist["route_long_name"]!
            route.route_short_name = Int32(dist["route_short_name"]!)!
        }
    }
    
    private func loadShapes() {
        let fileName = "shapes.txt"
        let csv = getCSV(fileName)
        self.updateProgress(value: 443)
        enumerateCSV(csv, entityName: K.CoreData.Entities.Shapes, progressWeight: 1904) { dist, context in
            let shape = Shapes(context: context)
            shape.shape_id = Int32(dist["shape_id"]!)!
            shape.shape_pt_lat = Double(dist["shape_pt_lat"]!)!
            shape.shape_pt_lon = Double(dist["shape_pt_lon"]!)!
            shape.shape_pt_sequence = Int16(dist["shape_pt_sequence"]!)!
        }
    }
    
    private func loadStops() {
        let fileName = "stops.txt"
        let csv = getCSV(fileName)
        self.updateProgress(value: 39)
        enumerateCSV(csv, entityName: K.CoreData.Entities.Stops, progressWeight: 562) { dist, context in
            let stop = Stops(context: context)
            stop.stop_code = Int32(dist["stop_code"]!)!
            stop.stop_id = Int32(dist["stop_id"]!)!
            stop.stop_name = dist["stop_name"]
            stop.stop_lat = Double(dist["stop_lat"]!)!
            stop.stop_lon = Double(dist["stop_lon"]!)!
        }
    }
    
    private func loadStopTimes() {
        let fileName = "stop_times.txt"
        let csv = getCSV(fileName)
        self.updateProgress(value: 8998)
        enumerateCSV(csv, entityName: K.CoreData.Entities.StopTimes, progressWeight: 13000) { dist, context in
            let stopTime = StopTimes(context: context)
            stopTime.trip_id = Int32(dist["trip_id"]!)!
            stopTime.stop_id = Int32(dist["stop_id"]!)!
            stopTime.stop_sequence = Int16(dist["stop_sequence"]!)!
            stopTime.arrival_time = dist["arrival_time"]!
            stopTime.departure_time = dist["departure_time"]!
            stopTime.stop_headsign = dist["stop_headsign"]!
        }
    }
    
    private func loadTrips() {
        let fileName = "trips.txt"
        let csv = getCSV(fileName)
        self.updateProgress(value: 312)
        enumerateCSV(csv, entityName: K.CoreData.Entities.Trips, progressWeight: 1094) { dist, context in
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
    
    private func concurentLoadStopTime(){
        let fileName = "stop_times.txt"
        let csv = getCSV(fileName)
        self.updateProgress(value: 8998)
        enumerateCSVConCurrent(csv, entityName: K.CoreData.Entities.StopTimes)
    }
    
    private func enumerateCSVConCurrent(_ csv : CSV<Enumerated>, entityName : String) {
        let total = csv.rows.count
        let rowPerBatch = 250000
        let totalBatches = (total / rowPerBatch) + 1
        debugPrint("Total rows: \(total), so total threads running: \(totalBatches)")
        serialQueue.async {
            self.totalStopTimeThreads = totalBatches
        }
        for batch in 0..<totalBatches {
            let startCount = (batch * rowPerBatch) + 1
            pc.performBackgroundTask { context in
                let time = Date()
                var i = 0
                do{
                    try csv.enumerateAsArray(startAt: startCount,rowLimit: rowPerBatch) { arr in
                        let stopTime = StopTimes(context: context)
                        stopTime.trip_id = Int32(arr[0])!
                        stopTime.stop_id = Int32(arr[3])!
                        stopTime.stop_sequence = Int16(arr[4])!
                        stopTime.arrival_time = arr[1]
                        stopTime.departure_time = arr[2]
                        stopTime.stop_headsign = arr[5]
                        i = i+1
                        if(i % 10000 == 0){
                            self.saveContext(context: context)
                        }
                    }
                } catch {
                    debugPrint("Error Adding data for \(entityName)")
                }
                self.saveContext(context: context)
                self.updateLoadResult(entityName, concurrent: true)
                self.printTime(since: time, task: "Loading \(entityName) in batch \(batch)")
                
                self.updateProgress(value: 7466 * self.pow(0.4574, times: batch))
            }
        }
    }
    
    private func enumerateCSV(_ csv : CSV<Enumerated>, entityName : String, progressWeight: Double, _ handler: @escaping ([String : String], _ context: NSManagedObjectContext) -> Void) {
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
                debugPrint("Error Adding data for \(entityName)")
            }
            self.saveContext(context: context)
            self.printTime(since: time, task: "Loading \(entityName)")
            self.updateLoadResult(entityName)
            self.updateProgress(value: progressWeight)
        }
    }
    
    private func getCSV(_ fileName: String) -> CSV<Enumerated> {
        let stamp = Date()
        var csv : CSV<Enumerated>? = nil
        let fileURL = documentsUrl.appendingPathComponent(fileName)
        do{
            csv = try CSV<Enumerated>(url: fileURL, delimiter: .comma, loadColumns: false)
        }catch{
            debugPrint("Error Loading File \(fileName)")
        }
        printTime(since: stamp, task: "Get CSV for \(fileName)")
        
        return csv!
    }
    
    //MARK: - Database delete helpers
    
    private func deleteAllEntity(_ entityName : String) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        self.pc.performBackgroundTask { context in
            let date = Date()
            do {/*
                let items = try context.fetch(request)
                for item in items {
                    context.delete(item as! NSManagedObject)
                }
                self.saveContext(context: context)*/
                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                try context.executeAndMergeChanges(using: batchDeleteRequest)
                self.saveContext(context: context)
            }
            catch {
                debugPrint("Error Fetching data from context. \(error)")
            }
            self.printTime(since: date, task: "Deleting \(entityName) database")
            self.updateDeleteResult(entityName)
        }
        
        if(entityName == K.CoreData.Entities.Routes){
            self.updateProgress(value: 77)
        } else if(entityName == K.CoreData.Entities.Stops){
            self.updateProgress(value: 1)
        } else if(entityName == K.CoreData.Entities.StopTimes){
            self.updateProgress(value: 1904)
        } else if(entityName == K.CoreData.Entities.Trips){
            self.updateProgress(value: 95)
        } else if(entityName == K.CoreData.Entities.Shapes){
            self.updateProgress(value: 2671)
        }
    }
    
    //MARK: - Task completion helpers
    
    private func initializeTaskCompletionData(){
        serialQueue.async {
            self.initializeAEntityDictionaryToFalse(&self.TasksAdd)
            self.initializeAEntityDictionaryToFalse(&self.TasksDelete)
        }
    }
    
    private func initializeAEntityDictionaryToFalse(_ Tasks : inout [String:Bool]){
        for entity in K.CoreData.Entities.all{
                Tasks[entity] = false
        }
    }
    
    private func checkIfDoneProcessing(_ concurrent: Bool = false){
        if(self.totalStopTimeThreadsCompleted < self.totalStopTimeThreads && concurrent){
            return
        }
        
        for entity in K.CoreData.Entities.all{
            if(!self.TasksAdd[entity]! || !self.TasksDelete[entity]!){
                return
            }
        }
        
        self.delegate!.DataMangager(self, didFinishLoadingCoreData: Void())
    }
    
    private func updateLoadResult(_ entityName: String, concurrent: Bool = false){
        serialQueue.async {
            self.updateTaskToComplete(&self.TasksAdd, entityName)
            if(concurrent){
                self.totalStopTimeThreadsCompleted += 1
            }
            self.checkIfDoneProcessing(concurrent)
        }
    }
    
    private func updateDeleteResult(_ entityName: String){
        serialQueue.async {
            self.updateTaskToComplete(&self.TasksDelete, entityName)
        }
    }
    
    private func updateTaskToComplete(_ task : inout [String:Bool], _ entityName: String){
            task[entityName] = true    }
    
    //MARK: - Core Data Helpers
    
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
    
    //MARK: - Local Misc Helpers
    
    func printTime(since startTime: Date, task : String){
        let tsf = String(format: "%3.0f", startTime.timeIntervalSinceNow * -1000.0)
        debugPrint("\(task) Took: \(tsf)")
    }
    
    private func pow(_ base: Double, times: Int) -> Double{
        var start = 1.0
        for _ in 0..<times{
            start = start * base
        }
        return start
    }
    
    //MARK: - ProgressNotifier
    
    private func updateProgress(value : Double){
        self.progressQueue.async {
            let total = 31300.0
            self.totalCompletedForNotification += value
            self.delegate?.DataMangager(self, updatedProgress: Double(self.totalCompletedForNotification/total))
        }
    }
    
}

protocol DataMangagerInitializerDelegate {
    func DataMangager(_ dataManager : DataMangagerInitializer, didFinishLoadingCoreData: Void)
    func DataMangager(_ dataManager: DataMangagerInitializer, updatedProgress: Double)
}

extension NSManagedObjectContext {
    
    /// Executes the given `NSBatchDeleteRequest` and directly merges the changes to bring the given managed object context up to date.
    ///
    /// - Parameter batchDeleteRequest: The `NSBatchDeleteRequest` to execute.
    /// - Throws: An error if anything went wrong executing the batch deletion.
    public func executeAndMergeChanges(using batchDeleteRequest: NSBatchDeleteRequest) throws {
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        let result = try execute(batchDeleteRequest) as? NSBatchDeleteResult
        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: result?.result as? [NSManagedObjectID] ?? []]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
    }
}
