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
    
    func startTimer(){
        timer = Timer.scheduledTimer(timeInterval: 10,
                                     target: self,
                                     selector: #selector(self.updateMap),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    @objc func updateMap(){
            timeStarted = Date()
            self.fetchDataVehiclePositions().resume()
        
    }
    
    @IBAction func Update(_ sender: Any) {
            
            self.fetchDataVehiclePositions().resume()
        
    }
    
    func centerMap(){
        let center = CLLocationCoordinate2D(latitude: 48.472523, longitude: -123.303513)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        self.mapView.setRegion(region, animated: true)
    }
    
    func fetchDataVehiclePositions() -> URLSessionDataTask{
        //let url = URL(string: "https://victoria.mapstrat.com/current/gtfrealtime_VehiclePositions.bin")!
        //let url = URL(string: "https://cdn.mbta.com/realtime/VehiclePositions.pb")!
        let url = URL(string: "https://data.texas.gov/download/eiei-9rpf/application%2Foctet-stream")!
    
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
                                Timer.scheduledTimer(timeInterval: 3,
                                    target: self,
                                    selector: #selector(self.updateMap),
                                    userInfo: nil,
                                    repeats: false)
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
        let allAnnotations = self.mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)
    }
    
    func showEntities(_ message : TransitRealtime_FeedMessage){
        let seconds = (timeStarted.timeIntervalSinceNow * -1000.0)
        self.i = self.i + 1
        message.entity.forEach { entity_data in
            if busAnnotations[entity_data.vehicle.vehicle.id] != nil  {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 5) { [self] in
                        busAnnotations[entity_data.vehicle.vehicle.id]!.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(entity_data.vehicle.position.latitude), longitude: CLLocationDegrees(entity_data.vehicle.position.longitude))
                        if(entity_data == message.entity.last){
                            let tsf = String(format: "%3.0f", lastFetch.timeIntervalSinceNow * -1000.0)
                            lastFetch = Date()
                            print("Updated " + String(self.i) + ": " + "#vec" + String(message.entity.count) + " took: " + String(format: "%3.0f", seconds) + " TNF: " + tsf)
                        }
                        
                        if (self.scheduledAReun){
                            startTimer()
                            self.scheduledAReun = false
                        }
                        
                        if (self.i % 5 == 0){
                            var keysToRemove : [String] = []
                            busAnnotations.forEach { (key: String, value: MKPointAnnotation) in
                                if(!message.entity.contains(where: { entity in
                                    entity.vehicle.vehicle.id == key
                                })) {
                                    keysToRemove.append(key)
                                }
                            }
                            
                            DispatchQueue.main.async {
                                keysToRemove.forEach { key in
                                    if self.busAnnotations[key] != nil {
                                        self.mapView.removeAnnotation(self.busAnnotations[key]!)
                                        self.busAnnotations.removeValue(forKey: key)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                busAnnotations[entity_data.vehicle.vehicle.id] = MKPointAnnotation()
                busAnnotations[entity_data.vehicle.vehicle.id]!.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(entity_data.vehicle.position.latitude), longitude: CLLocationDegrees(entity_data.vehicle.position.longitude))
                let addAnnotation = busAnnotations[entity_data.vehicle.vehicle.id]!
                DispatchQueue.main.async {
                    self.mapView.addAnnotation(addAnnotation)
                    if(entity_data.hashValue == message.entity.last?.hashValue){
                        self.lastFetch = Date()
                        print("Updated " + String(self.i) + ": " + "#vec" + String(message.entity.count) + " took: " + String(format: "%3.0f", seconds) )
                    }
                }
            }
        }
    }
}
