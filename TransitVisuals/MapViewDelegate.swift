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
            
        }else if (annotation is BusPointAnnotation){
            let nibName = "BusAnnotation"
                        
            let reuseIdentifier = "EmptyVehicle"
            
            var annotationView: MKAnnotationView?
            let viewFromNib = Bundle.main.loadNibNamed(nibName, owner: self, options: nil)?.first as! BusAnnotation

            // here configure label and imageView
            
            if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) {
                if dequeuedAnnotationView.subviews.isEmpty {
                    dequeuedAnnotationView.addSubview(viewFromNib)
                }
                annotationView = dequeuedAnnotationView
                annotationView?.annotation = annotation
            } else {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                annotationView?.addSubview(viewFromNib)
            }
             
            annotationView?.layer.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            annotationView?.canShowCallout = true
            let customView = annotationView!.subviews.first as? BusAnnotation
            customView?.frame = annotationView!.frame
            let title = extractBusNumber(annotation.title ?? "")
            customView?.busNumberLabel.text = title
            
            customView?.backgroundLayer.layer.cornerRadius = (customView?.backgroundLayer.frame.size.width ?? 40 ) / 2
            customView?.backgroundLayer.layer.borderWidth = 2
            if (annotation.title == ""){
                customView?.backgroundLayer.layer.borderColor = #colorLiteral(red: 0.4392156899, green: 0.01176470611, blue: 0.1921568662, alpha: 1).cgColor
            }else{
                customView?.backgroundLayer.layer.borderColor = #colorLiteral(red: 0.01372012775, green: 0.4772869349, blue: 0.9992420077, alpha: 1).cgColor
            }
            let bearing = (annotation as! BusPointAnnotation).bearing
            
            customView?.rotateTriangle(bearing)
            customView?.observe(annotation as! BusPointAnnotation)
            //self.mapView.camera.heading
            return annotationView
        }
        
        return nil
            
    }
    
    //TODO: Make the extraction better
    func extractBusNumber(_ title: String?) -> String{
        if let title = title {
            let title_prefix = String(title.prefix(3))
            var returnString = ""
            var found = false
            title_prefix.forEach { Character in
                if !Character.isWhitespace{
                    if(!found){
                        returnString.append(Character)
                    }
                }else{
                    found = true
                }
            }
            return returnString
        }
        return ""
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
}

extension BinaryFloatingPoint {
    func inRadians() -> Self {
        return self * .pi / 180
    }
}




