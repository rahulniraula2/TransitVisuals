//
//  Constants.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2022-08-17.
//

import UIKit

struct K {
    static let data = 2 // 1 boston, 2 victoria, 3 Texas
    
    struct DataSources {
        struct Boston {
            static let vehicleRealTimeSource = URL(string: "https://cdn.mbta.com/realtime/VehiclePositions.pb")!
            static let gtfsOfflineSource =  URL(string: "https://cdn.mbta.com/MBTA_GTFS.zip")!
            static let tripUpdateRealTimeSource = URL(string: "https://cdn.mbta.com/realtime/TripUpdates.pb")!
        }
        struct Victoria {
            static let vehicleRealTimeSource = URL(string: "https://victoria.mapstrat.com/current/gtfrealtime_VehiclePositions.bin")!
            static let gtfsOfflineSource =  URL(string: "https://victoria.mapstrat.com/current/google_transit.zip")!
            static let tripUpdateRealTimeSource = URL(string: "https://victoria.mapstrat.com/current/gtfrealtime_TripUpdates.bin")!
        }
        struct Texas {
            static let vehicleRealTimeSource = URL(string: "https://data.texas.gov/download/eiei-9rpf/application%2Foctet-stream")!
        }
        struct localVictoria {
            static let vehicleRealTimeSource = URL(string: "/Users/rahulniraula/Desktop/vehicleupdates.pb")!
            static let gtfsOfflineSource =  URL(string: "/Users/rahulniraula/Desktop/google_transit.zip")!
        }
        struct Seattle{
            static let vehicleRealTimeSource = URL(string: "https://s3.amazonaws.com/kcm-alerts-realtime-prod/vehiclepositions.pb")!
            static let gtfsOfflineSource =  URL(string: "https://metro.kingcounty.gov/GTFS/google_transit.zip")!
            static let tripUpdateRealTimeSource = URL(string: "https://s3.amazonaws.com/kcm-alerts-realtime-prod/tripupdates.pb")!
        }
    }
    
    static func FindRealTimePositionURL() -> URL {
        switch K.data{
        case 1:
            return K.DataSources.Boston.vehicleRealTimeSource
        
        case 2:
            return K.DataSources.Victoria.vehicleRealTimeSource
            
        case 3:
            return K.DataSources.Texas.vehicleRealTimeSource
        case 4:
            return K.DataSources.Seattle.vehicleRealTimeSource
        
        default:
            return Self.DataSources.Boston.vehicleRealTimeSource
        }
    }
    
    static func FindGtfsOfflineSourceURL() -> URL {
        switch K.data{
        case 1:
            return K.DataSources.Boston.gtfsOfflineSource
        
        case 2:
            return Self.DataSources.Victoria.gtfsOfflineSource
        case 4:
            return Self.DataSources.Seattle.gtfsOfflineSource
        
        default:
            return Self.DataSources.Boston.gtfsOfflineSource
        }
    }
    
    static func FindTripUpdateRealTimeURL() -> URL {
        switch K.data{
        case 1:
            return self.DataSources.Boston.tripUpdateRealTimeSource
        case 2:
            return Self.DataSources.Victoria.tripUpdateRealTimeSource
        case 4:
            return Self.DataSources.Seattle.tripUpdateRealTimeSource
        
        default:
            return Self.DataSources.Victoria.tripUpdateRealTimeSource
        }
    }
    
    struct CoreData {
        struct Entities{
            static let Routes = "Routes"
            static let Shapes = "Shapes"
            static let Stops = "Stops"
            static let StopTimes = "StopTimes"
            static let Trips = "Trips"
            static let all = [StopTimes, Trips, Shapes, Stops, Routes ]
        }
    }
    
   
}
