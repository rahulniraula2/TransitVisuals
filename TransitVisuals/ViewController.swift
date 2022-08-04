//
//  ViewController.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2022-08-01.
//

import UIKit
import MapKit
import SwiftProtobuf

class ViewController: UIViewController, URLSessionDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    let urlSession = URLSession(configuration: .default)
    var i = 0
    var busAnnotations = [String:MKPointAnnotation]()
    var oldMessageHash : Int = -1
    var scheduledAReun = false
    var timeStarted = Date()
    var lastFetch = Date()
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centerMap()
        mapView.delegate = self
        fetchDataVehiclePositions().resume()
        startTimer()
    }
}
    


    


