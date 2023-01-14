//
//  TripDeterminer.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2023-01-13.
//

import Foundation

class TripDeterminer{
    
    static let shared = TripDeterminer()
    
    var model = [TimeDeterminerModel]()
    var allTripIDsToday : [Int32]? = nil
    
    let processQueue = DispatchQueue(label: "TripDeterminer.regularProcess", qos: .default)
    
    func updateSharedModelToLatestTime(){
        processQueue.async() {
            let start = Date.now
            let allCurrentStopTimes = self.getStopTimesInCurrentTimeFrame()

            for stopTime in allCurrentStopTimes {
                if let model_item = self.model.first(where: {$0.trip.trip_id == stopTime.trip_id}){
                    if(stopTime.isEarilerThan(model_item.stopTime) != nil){
                        model_item.updateStopTime(stopTime: stopTime)
                    }
                }else{
                    let newModel = TimeDeterminerModel(stopTime: stopTime)
                    self.model.append(newModel)
                }
            }
            DateUtility.printTime(since: start, task: "Updating model for determiner")
        }
    }
    
    func getAllTripsFromToday() -> [Int32]{
        if let allTripIDsToday = self.allTripIDsToday{
            return allTripIDsToday
        }else{
            let serviceID =  ServiceFetcher.shared.getServiceID()
            let trips = TripQueryManager.shared.getTrips(withServiceID: serviceID)
            let allTrips = trips.map({ trip in
                return trip.trip_id
            })
            self.allTripIDsToday = allTrips
            return allTrips
        }
    }
    
    func updateVehicleModel(vehicle: TransitRealtime_VehiclePosition) -> Trips?{
        
        return nil
    }
    
    func getStopTimesInCurrentTimeFrame() -> [StopTimes]{
        let allTripIDs = self.getAllTripsFromToday()
        return StopTimesQueryManager.shared.queryAllCurrentTrips(tripIDs: allTripIDs)
    }
    
}

class TimeDeterminerModel {
    var trip : Trips
    var stopTime : StopTimes
    var stop : Stops
    var vehicleWeight : [String:Double]
    
    init(stopTime: StopTimes){
        self.trip = TripQueryManager.shared.getTrip(withID: stopTime.trip_id)!
        self.stop = BusStopQueryManager.shared.getStop(withID: stopTime.stop_id)
        self.stopTime = (stopTime)
        self.vehicleWeight = [:]
    }
    
    func updateStopTime(stopTime: StopTimes){
        self.trip = TripQueryManager.shared.getTrip(withID: stopTime.trip_id)!
        self.stop = BusStopQueryManager.shared.getStop(withID: stopTime.stop_id)
        self.stopTime = (stopTime)
    }
    
}
