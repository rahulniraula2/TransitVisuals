//
//  TripShapes.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2022-08-19.
//

import Foundation
import UIKit
import MapKit

class TripShapes {
    var shapeID : Int
    var coordinate : [CLLocationCoordinate2D]

    init(shapeID: Int, coordinate : [CLLocationCoordinate2D]){
        self.shapeID = shapeID
        self.coordinate = coordinate
    }
}

class Trips2 {
    var tripID : Int
    var routeID : Int 
    var headSign: String
    var blockID : Int
    var shapeID : Int
    
    init(tripID : Int, routeID : Int, headSign: String, blockID : Int, shapeID : Int){
        self.tripID = tripID
        self.routeID = routeID
        self.headSign = headSign
        self.blockID = blockID
        self.shapeID = shapeID
    }
}


