//
//  DataQueryManager.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2023-01-08.
//

import Foundation
import UIKit
import CoreData
import UIKit
import MapKit

class DataQueryManager {
    static let pc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    let context = pc.newBackgroundContext()
}
