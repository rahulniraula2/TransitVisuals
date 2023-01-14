//
//  TempViewControllerExtension.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2023-01-12.
//

import UIKit
import MapKit

extension ViewController{
  /*
    func startGuessingGame(){
        let todaysServiceID = getTodaysServiceID()
        let trips : [Trips] = DataQueryManager.getAllTrips(forServiceID: todaysServiceID)
        print("Today we have \(trips.count) trips")
        let tripIDs = trips.map { trip in
            return trip.trip_id
        }
        
        let afterMidnightTrips : [StopTimes] = DataQueryManager.filterForAfterMidnight(tripIDs: tripIDs)
        
        let tripIDsFinal = afterMidnightTrips.map { trip in
            return trip.trip_id
        }
        
        let uniqueTrips = Set(tripIDsFinal)
        
        print("Unique Trips in the timeframe \(uniqueTrips.count)")
        print(uniqueTrips)
        
        let shapesForUniqueTrips = trips.filter { trip in
            uniqueTrips.contains(trip.trip_id)
        }.map { trip in
            trip.shape_id
        }
        
        let uniqueShapeID = Set(shapesForUniqueTrips)
        
        loadRandomShapes(withShapeID: uniqueShapeID)

        //self.UpdateMap()
        //self.startTimer(5, repeats: true)
    }
    
    func loadRandomShapes(withShapeID ids: Set<Int32>){
        
        print("Total unique shapes is \(ids.count)")
        
        for id in ids {
            let cord = RouteShapeQueryManager().queryShape(withID: id)
            self.randomShapes[id] = cord
            let shape = DataConverters.getRouteOverlay(cord)
            randomOverlays[id] = shape
            self.mapView.addOverlay(shape)
        }
        
    }

    func handleVehicleUpdates2(_ vehicleUpdates: TransitRealtime_FeedMessage){
        print(" ")
        print(" ")
        print("Received \(vehicleUpdates.entity.count) updates")
        validateRandomBus(vehicleUpdates)
        
        guard let busID = self.randomVehicleID else {
            fatalError("No bus found")
        }
        
        let vehicle = vehicleUpdates.entity.first { entity in
            entity.vehicle.vehicle.id == busID
        }!
        let lat = CLLocationDegrees(vehicle.vehicle.position.latitude)
        let long = CLLocationDegrees(vehicle.vehicle.position.longitude)
        let location = CLLocationCoordinate2D(latitude: lat, longitude: long)
        if self.busHistory[busID] == nil {
            self.busHistory[busID] = []
        }
        let annot = MKPointAnnotation()
        annot.coordinate = location
        annot.title = "lochis"
        DispatchQueue.main.async {
            self.mapView.addAnnotation(annot)
        }
        
        self.busHistory[busID]?.append(location)
        
        if let overlay = self.mapOverlay {
            DispatchQueue.main.async {
                self.mapView.removeOverlay(overlay)
            }
        }
        
        let overlay = DataConverters.getRouteOverlay(self.busHistory[busID]!)
        self.mapOverlay = overlay
        
        DispatchQueue.main.async {
            self.mapView.addOverlay(overlay)
        }
        
        for shape in self.randomShapes {
            let key = shape.key
            let newAverage = self.minimalDistance(point: location, points: shape.value)
            if let oldAvg = self.distanceAverage[key]{
                self.distanceAverage[key] = (newAverage + oldAvg)/2.0
            }else{
                self.distanceAverage[key] = newAverage
            }
        }
        
        var average : Double? = nil
        
        for value in self.distanceAverage.values {
            if let avg = average{
                average = (avg + value) / 2
            }else {
                average = value
            }
        }
        
        print(average!)
        
        var keysToRemove = [Int32]()
        
        for (key, value) in self.distanceAverage {
            if(value > (average!) || !(value < 0.01)){
                keysToRemove.append(key)
            }
        }
        
        print("Removing \(keysToRemove.count) routes")
        
        let smallest = self.smallestValue(in: self.distanceAverage)!
        
        let trip = DataQueryManager.getTrip(forShapeID: smallest.key)
        print(smallest.key)
        print(trip?.trip_headsign!)
        
        for key in keysToRemove{
            DispatchQueue.main.async {
                self.mapView.removeOverlay(self.randomOverlays[key]!)
                self.randomShapes.removeValue(forKey: key)
                self.randomOverlays.removeValue(forKey: key)
                self.distanceAverage.removeValue(forKey: key)
            }
        }
        
        DataMangagerInitializer().printTime(since: self.startTime, task: "Doing All")
    }
    
    func smallestValue(in dictionary: [Int32 : Double]) -> (key: Int32, value: Double)? {
        var smallestValue: Double?
        var smallestKey: Int32?
        for (key, value) in dictionary {
            if smallestValue == nil {
                smallestValue = value
                smallestKey = key
            } else if value < smallestValue! {
                smallestValue = value
                smallestKey = key
            }
        }
        if let key = smallestKey, let value = smallestValue {
            return (key, value)
        } else {
            return nil
        }
    }
    
    func minimalDistance(point: CLLocationCoordinate2D, points: [CLLocationCoordinate2D]) -> Double {
        var minDistance = Double.infinity
        for p in points {
            let px = p.longitude
            let py = p.latitude
            let pointx = point.longitude
            let pointy = point.latitude
            let distance = sqrt(pow(Double(px - pointx), 2) + pow(Double(py - pointy), 2))
            if distance < minDistance {
                minDistance = distance
            }
        }
        return minDistance
    }
    
    func validateRandomBus(_ vehicleUpdates: TransitRealtime_FeedMessage){
        if self.randomVehicleID != nil {
            if !vehicleUpdates.entity.contains(where: { entity in
                entity.vehicle.vehicle.id == self.randomVehicleID
            }){
                print("Old tracked bus no longer avaliable")
                return
                //self.randomVehicleID = getRandomID(vehicleUpdates)
            }
        }else {
            self.randomVehicleID = getRandomID(vehicleUpdates)
        }
    }
    
    func getRandomID(_ vehicleUpdates: TransitRealtime_FeedMessage) -> String{
        
        let (TripID, vehicle, randomVehicleID) = getRandomTripID(vehicleUpdates)
        
        let lat = CLLocationDegrees(vehicle.vehicle.position.latitude)
        let long = CLLocationDegrees(vehicle.vehicle.position.longitude)
        let location = CLLocationCoordinate2D(latitude: lat, longitude: long)
        DispatchQueue.main.async {
            //self.mapView.setCenter(location, animated: true)
        }
        if let TripID = TripID{
            let actualRoute = TripQueryManager.shared.getTrip(withID: TripID)
            print("Actual Route \(actualRoute?.trip_headsign ?? "NA")")
            let cord = RouteShapeQueryManager.shared.queryShape(withID: actualRoute!.shape_id)
            self.randomShapes[0] = cord
            let overlay = DataConverters.getRouteOverlay(cord)
            DispatchQueue.main.async {
                self.mapView.addOverlay(overlay)
            }
        }else {
            print("unknown route")
        }
        
        print("Random bus selected with vehicle id: \(randomVehicleID)")
        return randomVehicleID
    }
    
    func getRandomTripID(_ vehicleUpdates: TransitRealtime_FeedMessage) -> (Int32?, TransitRealtime_FeedEntity, String){
        var returnVal : Int32? = nil
        var vehicle : TransitRealtime_FeedEntity? = nil
        var randomVehicleID : String? = nil
        
        //while(returnVal == nil){
            let vehicleIDs = vehicleUpdates.entity.map { entity in
                entity.vehicle.vehicle.id
            }
            let randomID = Int.random(in: 0..<vehicleIDs.count)
            randomVehicleID = vehicleIDs[randomID]
            
            vehicle = vehicleUpdates.entity.first { entity in
                entity.vehicle.vehicle.id == randomVehicleID
            }!
            
            returnVal = Int32(vehicle!.vehicle.trip.tripID)
        //}
        
        return (returnVal, vehicle!, randomVehicleID!)
    }
   */
}
