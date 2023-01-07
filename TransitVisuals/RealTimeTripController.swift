//
//  RealTimeTripController.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2022-08-04.
//

import UIKit
import MapKit
import SwiftProtobuf
import SwiftCSV
import ZIPFoundation

extension ViewController {
    
    func getTrips(){
        
        let url = K.FindTripUpdateRealTimeURL()
    
        self.urlSession.dataTask(with: url) { data,response,error  in
            if(error == nil){
                if let data = data {
                    let decodedData = self.decodeFetchedDataIntoMessage(data)
                    if let decodedData = decodedData{
                        decodedData.entity.forEach { transitRealtime_FeedEntity in
                            //print(transitRealtime_FeedEntity)
                            let timeDifference = Date.now.timeIntervalSince1970 - Double(((transitRealtime_FeedEntity.tripUpdate.stopTimeUpdate.first?.arrival.time)!))
                            let minutes = String(timeDifference / 60.0)
                            let stopID : String = transitRealtime_FeedEntity.tripUpdate.stopTimeUpdate.first!.stopID
                            self.tripUpdates[transitRealtime_FeedEntity.tripUpdate.trip.tripID] = "Arriving at " + stopID + " stop at" + minutes
                        }
                    }
                }
            }
        }.resume()
    }
    
}
