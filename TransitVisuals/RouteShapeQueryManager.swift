//
//  RouteShapeQueryManager.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2023-01-11.
//

import Foundation
import MapKit
import CoreData

class RouteShapeQueryManager: DataQueryManager {
    static let shared = RouteShapeQueryManager()
    var coordinatesForShapeID : [Int32 : MKPolyline] = [:]
    
    func getShape(withID id: Int32) -> MKPolyline{
        if let line = self.coordinatesForShapeID[id]{
            return line
        }else{
            let shape = queryShape(withID: id)
            let polyline = DataConverters.getRouteOverlay(shape)
            self.coordinatesForShapeID[id] = polyline
            return polyline
        }
    }
    
    func queryShape(withID id: Int32) -> [CLLocationCoordinate2D]{
        let context = RouteShapeQueryManager.pc.viewContext
        
        let fReq: NSFetchRequest<Shapes> = Shapes.fetchRequest()
        
        fReq.predicate = NSPredicate(format: "shape_id == %d", id)
        
        do{
            let shapes =  try context.fetch(fReq)
            let coordinates = getCoordinates(shapes)
            return coordinates
        }catch{
            print("Error Fetching Bus Stops")
        }
        return []
    }
    
    func getCoordinates(_ shape: Shapes) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: CLLocationDegrees(shape.shape_pt_lat), longitude: CLLocationDegrees(shape.shape_pt_lon))
    }
    
    func getCoordinates(_ shapes: [Shapes]) -> [CLLocationCoordinate2D] {
        
        var coordinates : [CLLocationCoordinate2D] = []
        
        let sortedShapes = shapes.sorted { a, b in
            a.shape_pt_sequence < b.shape_pt_sequence
        }
        
        for shape in sortedShapes {
            coordinates.append(getCoordinates(shape))
        }
        
        return coordinates
    }
    
}
