//
//  DateUtility.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2023-01-13.
//

import Foundation


class DateUtility {
    
    static func differenceBetween(_ timestamp: String, and timeStamp_other: String) -> Double {
        
        return Double.infinity
    }
    
    static func weightFor(_ timestamp: String) -> Int {
        let converted = Array(DateUtility.convertTimeToOverFlownFormat(timestamp))
        let currentTime = Array(DateUtility.getCurrentTimeInOverflownFormat())
        var weight : Int = 0
        
        weight += (getHour(timestamp: converted) - getHour(timestamp: currentTime))*60*60
        weight += (getMinutes(timestamp: converted) - getMinutes(timestamp: currentTime))*60
        weight += (getSeconds(timestamp: converted) - getSeconds(timestamp: currentTime))
        
        return abs(weight)
    }
    
    static func getHour(timestamp array: Array<Character>) -> Int {
        let currentHour = (Int(String(array[0]))! * 10 + Int(String(array[1]))!)
        return currentHour
    }
    
    static func getMinutes(timestamp array: Array<Character>) -> Int {
        let currentHour = (Int(String(array[3]))! * 10 + Int(String(array[4]))!)
        return currentHour
    }
    
    static func getSeconds(timestamp array: Array<Character>) -> Int {
        let currentHour = (Int(String(array[6]))! * 10 + Int(String(array[7]))!)
        return currentHour
    }
    
    static private func getCurrentTimeInOverflownFormat() -> String{
        let now = Date.now
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: now)
        return DateUtility.convertTimeToOverFlownFormat(timestamp)
    }
    
    static private func convertTimeToOverFlownFormat(_ timeStamp : String) -> String {
        var array = Array(timeStamp)
        let currentHour = (Int(String(array[0]))! * 10 + Int(String(array[1]))!)
        if(currentHour < 3){
            array[0] = "2"
            if(currentHour == 0){
                array[1] = "4"
            }else if(currentHour == 1){
                array[1] = "5"
            }else if(currentHour == 2){
                array[1] = "6"
            }else if(currentHour == 3){
                array[1] = "7"
            }else if(currentHour == 4){
                array[1] = "4"
            }
            return String(array)
        }
        return timeStamp
    }
    
    static func printTime(since startTime: Date, task : String){
        let tsf = String(format: "%3.0f", startTime.timeIntervalSinceNow * -1000.0)
        debugPrint("\(task) Took: \(tsf)")
    }
    
}

extension StopTimes {
    func isEarilerThan(_ other: StopTimes, knownWeight : Int? = nil) -> Int?{
        
        let currentWeight : Int
        
        if let knownWeight = knownWeight {
            currentWeight = knownWeight
        }else{
            currentWeight = DateUtility.weightFor(self.arrival_time!)
        }
        
        let otherWeight = DateUtility.weightFor(other.arrival_time!)
        
        if(currentWeight < otherWeight){
            return otherWeight
        }
        
        return nil
    }
}
