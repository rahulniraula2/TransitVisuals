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


