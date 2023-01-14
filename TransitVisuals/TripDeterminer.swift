//
//  TripDeterminer.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2023-01-13.
//

import Foundation
import MapKit

class TripDeterminer{
    
    static let shared = TripDeterminer()
    
    var model = [TimeDeterminerModel]()
    var allTripIDsToday : [Int32]? = nil
    
    var delegate : TripDeterminerDelegate?
    
    let processQueue = DispatchQueue(label: "TripDeterminer.regularProcess",qos: .userInteractive, attributes: .concurrent)
    
    
    func updateSharedModelToLatestTime(vehicleUpdates : TransitRealtime_FeedMessage){
        processQueue.async(flags: .barrier) {
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
            
            for model_item in self.model {
                for entity in vehicleUpdates.entity{
                    let vehicle = entity.vehicle
                    let dist_stop = model_item.getDistanceToStopForVehiclePosition(vehicle.position)
                    let dist_route = model_item.getMinDistanceToTripForVehiclePosition(vehicle.position)
                    let calulatedWeight = (dist_stop * 0.02) + (dist_route * 0.98)
                    if let weight = model_item.vehicleWeight[vehicle.vehicle.id]{
                        model_item.vehicleWeight[vehicle.vehicle.id] = (weight+calulatedWeight) / 2
                    }else{
                        model_item.vehicleWeight[vehicle.vehicle.id] = calulatedWeight
                    }
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
    
    func updateVehicleModel(vehicle: TransitRealtime_VehiclePosition){
        processQueue.async {
            guard vehicle.vehicle.id != "" else {
                return
            }
            
            let sortedModel = self.model.sorted { a, b in
                a.vehicleWeight[vehicle.vehicle.id]! < b.vehicleWeight[vehicle.vehicle.id]!
            }
            for model_item in sortedModel {
                if model_item.vehicleWeight.sorted(by: { a, b in
                    a.value < b.value
                }).first?.key == vehicle.vehicle.id{
                    self.delegate?.tripDeterminer(for: self, didDetermineTripForVehicleID: vehicle, trip: model_item.trip)
                    return
                }
            }
            self.delegate?.tripDeterminer(for: self, didDetermineTripForVehicleID: vehicle, trip: nil)
        }
    }
    
    func getResultForVehicle(vehicle: TransitRealtime_VehiclePosition){
        
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
    
    func getDistanceToStopForVehiclePosition(_ position: TransitRealtime_Position) -> CLLocationDistance{
        let stopCoordinates = CLLocationCoordinate2D(latitude: self.stop.stop_lat, longitude: self.stop.stop_lon)
        let pos_lat = CLLocationDegrees(position.latitude)
        let pos_lon = CLLocationDegrees(position.longitude)
        let vehicleCoordinates = CLLocationCoordinate2D(latitude: pos_lat, longitude: pos_lon)
        return vehicleCoordinates.distance(to: stopCoordinates)
    }
    
    func getMinDistanceToTripForVehiclePosition(_ position: TransitRealtime_Position) -> CLLocationDistance{
        let tripRoute = RouteShapeQueryManager.shared.getCoordinates(withID: self.trip.shape_id)
        let pos_lat = CLLocationDegrees(position.latitude)
        let pos_lon = CLLocationDegrees(position.longitude)
        let vehicleCoordinates = CLLocationCoordinate2D(latitude: pos_lat, longitude: pos_lon)
        return self.minimalDistance(point: vehicleCoordinates, points: tripRoute)
    }
    
    private func minimalDistance(point: CLLocationCoordinate2D, points: [CLLocationCoordinate2D]) -> CLLocationDistance {
        var minDistance = CLLocationDistance.infinity
        for p in points {
            let distance = point.distance(to: p)
            if distance < minDistance {
                minDistance = distance
            }
        }
        return minDistance
    }
    
}

protocol TripDeterminerDelegate {
    func tripDeterminer(for: TripDeterminer, didDetermineTripForVehicleID vehicleID: TransitRealtime_VehiclePosition, trip: Trips?)
    func tripDeterminer(for: TripDeterminer, finishedDeterminingTrips : Void)
}

extension CLLocationCoordinate2D {
    func distance(to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }
}
