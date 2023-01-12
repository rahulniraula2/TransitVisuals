//
//  RealTimeUpdater.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2023-01-11.
//

import Foundation

class RealTimeUpdater {
    
    static let shared = RealTimeUpdater()
    
    let session = URLSession(configuration: .default)
    
    var etagForURL = [String:String]()
    
    let serialQueue = DispatchQueue(label: "RealTimeUpdaterQueue")
    
    enum DataTaskError : Error {
        case failedToFetch
        case notModified
        case failedToDecode
    }
    
    func getUpdatedVehicles(_ completion: @escaping (_ vehicleUpdates : TransitRealtime_FeedMessage, _ tripUpdates : TransitRealtime_FeedMessage) -> Void) {
        serialQueue.async {
            Task.init {
                let vehiclePosition = await self.fetchDataVehiclePosition(K.FindRealTimePositionURL())
                let tripUpdates = await self.fetchDataVehiclePosition(K.FindTripUpdateRealTimeURL())
                
                switch(vehiclePosition, tripUpdates) {
                case (.success(let vehicles), .success(let trip)):
                    completion(vehicles, trip)
                default:
                    print("Not needed")
                }
            }
        }
    }
    
    func fetchDataVehiclePosition(_ url : URL) async -> Result<TransitRealtime_FeedMessage, DataTaskError>{
        let data = await fetchDataFromURL(url)
        switch data {
            
        case .success(let data):
            if let message = self.decodeFetchedDataIntoMessage(data) {
                return .success(message)
            }
        case .failure(let error):
            return .failure(error)
        }
        
        return .failure(DataTaskError.failedToDecode)
    }
    
    func fetchDataFromURL(_ url : URL) async -> Result<Data, DataTaskError> {
        do {
            let request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData)
            let (data, response) = try await self.session.data(for: request)
            if let etag = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Etag"){
                if let oldTag = self.etagForURL[url.absoluteString] {
                    if oldTag == etag {
                        return .failure(DataTaskError.notModified)
                    }
                }
                self.etagForURL[url.absoluteString] = etag
            }
            return .success(data)
            
        }catch {
            return .failure(DataTaskError.failedToFetch)
        }
    }
    
    func decodeFetchedDataIntoMessage(_ dataFromURL: Data) -> TransitRealtime_FeedMessage? {
        return try? TransitRealtime_FeedMessage(serializedData:dataFromURL)
    }
}
