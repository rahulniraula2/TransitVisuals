//
//  ViewController.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2022-08-01.
//

import UIKit
import MapKit
import SwiftProtobuf
import SwiftCSV
import ZIPFoundation

class ViewController: UIViewController, URLSessionDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    let urlSession = URLSession(configuration: .default)
    
    //Main counter for number of fetches in the application
    var i = 0
    
    var busAnnotations = [String:BusPointAnnotation]()
    var busStopAnnotations = [String:MKPointAnnotation]()
    var totalBusStops = 0
    
    var oldMessageHash : Int = -1
    
    var scheduledAReun = false
    
    var timeStarted = Date()
    var lastFetch = Date()
    var timer = Timer()
    
    var tripName  = [String:String]()
    var tripNames : [String] = []
    
    var tripUpdates = [String:String]()
    var busStopsShown = true
    
    var tripShape = [String: MKPolyline]()
    
    let defautls = UserDefaults.standard
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    
    var coreDataTime = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.mapType = .mutedStandard
        mapView.isRotateEnabled = false
        
        self.centerMap(animated: false)
        self.loadCoreData()
        
        /*ResourceManager().fetchInitialResources(for: self, progressHandler: updateProgressBar){
            DispatchQueue.main.async {
                self.initMap()
            }
        }*/
    }
    
    func loadCoreData(){
        let timeStarted1 = Date()
        self.coreDataTime = timeStarted1
        let dm = DataMangagerInitializer()
        dm.delegate = self
        dm.initializeDataBase()
        //dm.testLoadingLargeData()
        let tsf = String(format: "%3.0f", timeStarted1.timeIntervalSinceNow * -1000.0)
        print("Loading Core Data Took: \(tsf)")
    }
    
    func updateProgressBar(progress: Progress){
        DispatchQueue.main.async {
            self.progressBar.progress = Float(progress.fractionCompleted)
            var textBuilder = String(round(100 * (progress.fractionCompleted * 100)) / 100) + "% completed\n"
            
            if let estimatedTimeRemaining : TimeInterval = progress.estimatedTimeRemaining {
                let timeRemainingInSeconds = String(NSInteger(estimatedTimeRemaining) % 60)
                textBuilder += String("Estimated time remaining: " + timeRemainingInSeconds + "s")
            }
            
            self.progressLabel.text = textBuilder
        }
    }
    
    func hideLoadingView(hide: Bool){
        DispatchQueue.main.async {
            self.loadingView.isHidden = hide
        }
    }
    
}

extension ViewController: DataMangagerInitializerDelegate{
    func DataMangager(_ dataManager: DataMangagerInitializer, didFinishLoadingCoreData: Void) {
        DispatchQueue.main.async {
            debugPrint("DONE LOADING ALL DATA YEYYYYY")
            dataManager.printTime(since: self.coreDataTime, task: "Doing Everything")
        }
    }
}


    


    


