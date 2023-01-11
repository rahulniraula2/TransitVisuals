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
    let resourceManager = ResourceManager()

    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    
    var coreDataTime = Date()
    
    var isAtBigZoom = false {
        didSet {
            if(!oldValue && !isAtBigZoom){
                return
            }
            handleMapRegionChange(showStops: isAtBigZoom)
        }
    }
    var task : Task<Void, Error>? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        mapView.register(MKBusStopAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.delegate = self
        mapView.mapType = .mutedStandard
        mapView.isRotateEnabled = false
        
        self.centerMap(animated: false)
        self.resourceManager.delegate = self
        self.fetchDataIfNeeded()
    }
    
    func handleMapRegionChange(showStops: Bool){
        if(showStops){
            if let task = self.task {
                task.cancel()
                if(task.isCancelled){
                    print("Old Task was cancelled")
                }
            }
            self.task = Task{
                let stops = await BusStopQueryManager.shared.getAllBusStops(in: mapView.region)
                print("returned \(stops.count) stops")
                for stop in stops {
                    DispatchQueue.main.async {
                        if self.mapView.view(for: stop) == nil {
                            self.mapView.addAnnotation(stop)
                        }
                    }
                }
            }
        }else{
            for annot in mapView.annotations{
                if annot is BusStopAnnotation {
                    UIView.animate(withDuration: 2) {
                        self.mapView.removeAnnotation(annot)
                    }
                }
            }
        }
    }
    
    func fetchDataIfNeeded(){
        self.resourceManager.fetchInitialResources(for: self)
    }
    
    func updateProgressBar(progress: Double){
        let textBuilder = String(round(100 * (progress * 100)) / 100) + "% completed\n"
        
        DispatchQueue.main.async {
            self.progressBar.setProgress(Float(progress), animated: true)
            self.progressLabel.text = textBuilder
        }
    }
    
    func hideLoadingView(hide: Bool){
        DispatchQueue.main.async {
            self.loadingView.isHidden = hide
        }
    }
    
}

extension ViewController: ResourceManagerDelegate {
    func resourceManager(_ resourceManager: ResourceManager, updatedProgress: Double) {
        self.updateProgressBar(progress: updatedProgress)
    }
    
    func resourceManager(_ resourceManager: ResourceManager, didFinishLoadingData: Void) {
        DispatchQueue.main.async {
            debugPrint("DONE LOADING ALL DATA YEYYYYY")
            DataMangagerInitializer().printTime(since: self.coreDataTime, task: "Doing Everything")
        }
        //self.loadAllBusStops(display: true)
    }
    
    func resourceManager(_ resourceManager: ResourceManager, newDataAvaliable alert: UIAlertController){
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    func resourceManager(_ resourceManager: ResourceManager, updatedLoadingStatus loading: Bool){
        self.hideLoadingView(hide: !loading)
    }
}


    


    


