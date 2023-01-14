//
//  MapViewDelegate.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2022-08-04.
//

import Foundation
import MapKit

extension ViewController : MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        self.isAtBigZoom =  mapView.region.span.latitudeDelta < 0.02
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        if(annotation is BusStopAnnotation || annotation.title == "Bus Stop"){
            
            return MKBusStopAnnotationView(annotation: annotation, reuseIdentifier: MKBusStopAnnotationView.ReuseID)
            
        }else if let annotation = annotation as? BusPointAnnotation {
            
            let annotationView = BusAnnotation.getNewBusAnnotation(for: mapView, with: annotation)
            return annotationView
            
        }else if (annotation.title == "lochis"){
            var annotationView: MKAnnotationView?
            if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") {
                annotationView = dequeuedAnnotationView
                annotationView?.annotation = annotation
            } else {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            }
            
            return annotationView
        }
        return nil
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        // Make sure we are rendering a polyline.
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer()
        }

        // Create a specialized polyline renderer and set the polyline properties.
        let polylineRenderer = MKPolylineRenderer(overlay: polyline)
        polylineRenderer.strokeColor = arc4random() % 2 == 0 ? .black : .red
        polylineRenderer.lineWidth = 2
        return polylineRenderer
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? BusPointAnnotation{
            let shapeID = annotation.shapeID
            let overlay = RouteShapeQueryManager.shared.getShape(withID: shapeID)
            mapView.addOverlay(overlay)
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let annotation = view.annotation as? BusPointAnnotation{
            let shapeID = annotation.shapeID
            let overlay = RouteShapeQueryManager.shared.getShape(withID: shapeID)
            mapView.removeOverlay(overlay)
        }
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
}

extension BinaryFloatingPoint {
    func inRadians() -> Self {
        return self * .pi / 180
    }
}




