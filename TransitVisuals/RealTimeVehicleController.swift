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
    
    //UpdateMap is called by the timer
    @objc func UpdateMap(){
        self.timeStarted = Date()
        self.fetchDataVehiclePositions().resume()
    }
    
    //Update is called by the reset button
    //TODO: Rename to Reset
    @IBAction func Update(_ sender: Any) {
        //self.
        self.timer.invalidate()
        self.scheduledAReun = true
        self.removeAllAnnotations()
        self.oldMessageHash = -1
        self.timeStarted = Date()
        self.fetchDataVehiclePositions().resume()
    }
    
    //TODO: Center the map to include all the bus stops
    func centerMap(animated: Bool = true){
        let center = CLLocationCoordinate2D(latitude: 48.472523, longitude: -123.303513)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        DispatchQueue.main.async {
            self.mapView.setRegion(region, animated: animated)
        }
    }
    
    func fetchDataVehiclePositions() -> URLSessionDataTask{
        
        let url = K.FindRealTimePositionURL()
    
        return self.urlSession.dataTask(with: url) { data,response,error  in
            if(error == nil){
                if let data = data {
                    if(data.hashValue != self.oldMessageHash){
                        let decodedData = self.decodeFetchedDataIntoMessage(data)
                        if let decodedData = decodedData {
                            self.showEntities(decodedData)
                        }
                        self.oldMessageHash = data.hashValue
                    }else {
                        let tsf = String(format: "%3.0f", self.lastFetch.timeIntervalSinceNow * -1000.0)
                        print("Same data TNF:" + tsf + " NU:3s")
                        self.scheduledAReun = true
                        DispatchQueue.main.async {
                            self.timer.invalidate()
                            self.startTimer(3.0, repeats: false)
                        }
                    }
                    
                }
            }
        }
    }
        
    func decodeFetchedDataIntoMessage(_ dataFromURL: Data) -> TransitRealtime_FeedMessage? {
        do {
            return try TransitRealtime_FeedMessage(serializedData:dataFromURL)
        } catch {
            
        }
        return nil
    }
    
    func removeAllAnnotations(){
        busAnnotations.forEach { (key: String, value: MKPointAnnotation) in
            DispatchQueue.main.async {
                self.mapView.removeAnnotation(value)
            }
        }
        busAnnotations.removeAll()
    }
    
    func showEntities(_ message : TransitRealtime_FeedMessage){
        
        let url = URL(string: "https://victoria.mapstrat.com/current/gtfrealtime_TripUpdates.bin")!
    
        self.urlSession.dataTask(with: url) { [self] data,response,error  in
            if(error == nil){
                if let data = data {
                    let decodedData = self.decodeFetchedDataIntoMessage(data)
                    if let decodedData = decodedData{
                        decodedData.entity.forEach { transitRealtime_FeedEntity in
                            let timeDifference = Double(((transitRealtime_FeedEntity.tripUpdate.stopTimeUpdate.first?.arrival.time) ?? 0)) - Date.now.timeIntervalSince1970
                            let minutes = String(round(timeDifference * 100)/100)
                            let stopID : String = transitRealtime_FeedEntity.tripUpdate.stopTimeUpdate.first?.stopID ?? "-1"
                            self.tripUpdates[transitRealtime_FeedEntity.tripUpdate.trip.tripID] = "Arriving at " + stopID + " stop at" + minutes
                        }
                    }
                }
                displayUpdatedTripsAndVehicles(message)
            }
        }.resume()
        
    }
    
    func displayUpdatedTripsAndVehicles(_ message : TransitRealtime_FeedMessage){
        let seconds = (self.timeStarted.timeIntervalSinceNow * -1000.0)
        self.i = self.i + 1
        message.entity.forEach { entity_data in
            if let annotationToAnimate = self.busAnnotations[entity_data.vehicle.vehicle.id]  {
                DispatchQueue.main.async {
                    
                    annotationToAnimate.title = self.tripName[entity_data.vehicle.trip.tripID] ?? ""
                    annotationToAnimate.subtitle = self.tripUpdates[entity_data.vehicle.trip.tripID] ?? ""
                    UIView.animate(withDuration: 1, animations: {
                        annotationToAnimate.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(entity_data.vehicle.position.latitude), longitude: CLLocationDegrees(entity_data.vehicle.position.longitude))
                        //TODO: Research how to update the view when title/subtitle changes
                        
                    })
                    UIView.animate(withDuration: 1, animations: {
                        annotationToAnimate.bearing =  CGFloat(entity_data.vehicle.position.bearing - 90).inRadians()
                    })
                    
                }
            } else {
                let annotationToAdd = BusPointAnnotation()
                annotationToAdd.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(entity_data.vehicle.position.latitude), longitude: CLLocationDegrees(entity_data.vehicle.position.longitude))
                
                annotationToAdd.title = self.tripName[entity_data.vehicle.trip.tripID] ?? ""
                annotationToAdd.tripID = entity_data.vehicle.trip.tripID
                annotationToAdd.subtitle = self.tripUpdates[entity_data.vehicle.trip.tripID] ?? ""
                
                annotationToAdd.bearing = CGFloat(entity_data.vehicle.position.bearing - 90).inRadians()
                busAnnotations[entity_data.vehicle.vehicle.id] = annotationToAdd
                
                DispatchQueue.main.async {
                    self.mapView.addAnnotation(annotationToAdd)
                }
            }
        }

        GarbageCollector(message)
        
        let tsf = String(format: "%3.0f", self.lastFetch.timeIntervalSinceNow * -1000.0)
        lastFetch = Date()
        DispatchQueue.main.sync {
            print("Updated " + String(self.i) + ": " + "#V\(self.mapView.annotations.count - self.totalBusStops)/" + String(message.entity.count) + " took: " + String(format: "%3.0f", seconds) + " TNF: " + tsf)
        }
        
        if (self.scheduledAReun){
            self.startTimer(20.0, repeats: true)
            self.scheduledAReun = false
        }
    }
    
    func GarbageCollector(_ message : TransitRealtime_FeedMessage){
        var keysToRemove : [String] = []
        if (self.i % 3 == 0){
            var busRemovalCount = 0
            let cleanUpTimeStart = Date()
            self.busAnnotations.forEach { (key: String, value: MKPointAnnotation) in
                if(!message.entity.contains(where: { entity in
                    entity.vehicle.vehicle.id == key
                })) {
                    keysToRemove.append(key)
                }
            }
            keysToRemove.forEach { key in
                let val = self.busAnnotations[key]
                if let val = val {
                    DispatchQueue.main.async {
                        UIView.animate(withDuration: 2) {
                            self.mapView.removeAnnotation(val)
                        }
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


