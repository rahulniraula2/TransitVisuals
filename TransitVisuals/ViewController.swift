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
    
    var busAnnotations = [String:BusPointAnnotation]()
    
    let defautls = UserDefaults.standard
    let resourceManager = ResourceManager()
    var timer = Timer()

    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.mapType = .mutedStandard
        mapView.isRotateEnabled = false
        
        registerAnnotations()
        self.centerMap(animated: false)
        self.resourceManager.delegate = self
        self.fetchDataIfNeeded()
        
    }
    
    func registerAnnotations(){
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        mapView.register(MKBusStopAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
    }
    
    func handleMapRegionChange(showStops: Bool){
        if(showStops){
            Task{
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
                    DispatchQueue.main.async {
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
            DataMangagerInitializer().printTime(since: self.coreDataTime, task: "Loading Database")
            self.UpdateMap()
            self.startTimer(5, repeats: true)
        }
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


    


    


