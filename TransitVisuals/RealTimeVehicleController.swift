//
//  RealTimeVehicleController.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2022-08-04.
//

import Foundation
import MapKit
import SwiftProtobuf

extension ViewController {
    
    func startTimer(_ seconds: Double, repeats: Bool){
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: seconds,
                                         target: self,
                                         selector: #selector(self.UpdateMap),
                                         userInfo: nil,
                                         repeats: repeats)
        }
    }
    
    @objc func UpdateMap(){
        RealTimeUpdater.shared.getUpdatedVehicles(handleUpdates)
    }
    
    func handleUpdates(_ vehicleUpdates : TransitRealtime_FeedMessage, _ tripUpdates : TransitRealtime_FeedMessage) {
        TripDeterminer.shared.updateSharedModelToLatestTime()
        let messages = self.handleTripUpdates(tripUpdates)
        print("Received \(vehicleUpdates.entity.count) updates")
        self.handleVehicleUpdates(vehicleUpdates, messages)
    }
    
    func handleTripUpdates(_ tripUpdates : TransitRealtime_FeedMessage) -> [Int32 : String] {
        let count = tripUpdates.entity.count
        var messages = [Int32 : String]()
        
        for i in 0..<count {
            let tripUpdate = tripUpdates.entity[i].tripUpdate
            let tripID = Int32(tripUpdate.trip.tripID) ?? -1
            
            let timeDifference = Double(((tripUpdate.stopTimeUpdate.first?.arrival.time) ?? 0)) - Date.now.timeIntervalSince1970
            let minutes = String(round(timeDifference * 100)/100)
            
            let stopID : String = tripUpdate.stopTimeUpdate.first?.stopID ?? "-1"
            
            messages[tripID] = "Arriving at \(BusStopQueryManager.shared.getBusStop(withID: Int32(stopID)!).title ?? "NA") stop in \(minutes)"
        }
        return messages
    }
    
    func handleVehicleUpdates(_ vehicleUpdates : TransitRealtime_FeedMessage, _ messages : [Int32 : String]){
        
        let tripIDs = vehicleUpdates.entity.map { entity in
            Int32(entity.vehicle.trip.tripID) ?? -1
        }
        TripQueryManager.shared.getTrips(withIDs: tripIDs)
        
        vehicleUpdates.entity.forEach { entity_data in
            let tripID = Int32(entity_data.vehicle.trip.tripID) ?? -1
            let vehicleID = entity_data.vehicle.vehicle.id
            
            if let annotationToAnimate = self.busAnnotations[vehicleID]  {
                //self.updateVehicleAnnotation(annotationToAnimate, entity_data: entity_data, message: messages[tripID])
                annotationToAnimate.configureAnnotation(to: entity_data, tripMessage: messages[tripID])
            } else {
                let annotationToAdd = BusPointAnnotation()
                annotationToAdd.configureAnnotation(to: entity_data, tripMessage: messages[tripID])
                busAnnotations[vehicleID] = annotationToAdd
                DispatchQueue.main.async {
                    self.mapView.addAnnotation(annotationToAdd)
                }
            }
            
            if(tripID == -1){
                if let determinedTrip = TripDeterminer.shared.updateVehicleModel(vehicle: entity_data.vehicle){
                    //trip was determined
                    
                }else{
                    //trip could not be determined
                }
            }
        }
        
        self.GarbageCollector(vehicleUpdates)
    }
    
    func updateVehicleAnnotation(_ annotationToAnimate: BusPointAnnotation, entity_data : TransitRealtime_FeedEntity, message: String?){
        DispatchQueue.main.async {
            annotationToAnimate.updateSubtitle(tripMessage: message)
            UIView.animate(withDuration: 1, animations: {
                annotationToAnimate.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(entity_data.vehicle.position.latitude), longitude: CLLocationDegrees(entity_data.vehicle.position.longitude))
                annotationToAnimate.bearing =  CGFloat(entity_data.vehicle.position.bearing - 90).inRadians()
            })
        }
    }
    
    //Update is called by the reset button
    //TODO: Rename to Reset
    @IBAction func Update(_ sender: Any) {
        //self.
        self.timer.invalidate()
        self.removeAllAnnotations()
        startTimer(1, repeats: true)
    }
    
    //TODO: Center the map to include all the bus stops
    func centerMap(animated: Bool = true){
        let center = CLLocationCoordinate2D(latitude: 48.472523, longitude: -123.303513)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        DispatchQueue.main.async {
            self.mapView.setRegion(region, animated: animated)
        }
    }
    
    func removeAllAnnotations(){
        busAnnotations.forEach { (key: String, value: MKPointAnnotation) in
            DispatchQueue.main.async {
                self.mapView.removeAnnotation(value)
            }
        }
        busAnnotations.removeAll()
    }
    
    func GarbageCollector(_ message : TransitRealtime_FeedMessage){
        DispatchQueue.global(qos: .background).async{
            var keysToRemove : [String] = []
            var busRemovalCount = 0
            let cleanUpTimeStart = Date()
            
            let vehicleIDs = message.entity.map { enitity in
                enitity.vehicle.vehicle.id
            }
            
            keysToRemove = self.busAnnotations.keys.filter({ key in
                !vehicleIDs.contains(key)
            })
            
            keysToRemove.forEach { key in
                if let val = self.busAnnotations[key] {
                    DispatchQueue.main.async {
                        self.mapView.removeAnnotation(val)
                        self.busAnnotations.removeValue(forKey: key)
                        busRemovalCount += 1
                    }
                }
            }
            let cleanUptime = String(format: "%3.0f", cleanUpTimeStart.timeIntervalSinceNow * -1000.0)
            print("Clean up took:" + cleanUptime + " Removed \(busRemovalCount) buses")
        }
    }
    
}


