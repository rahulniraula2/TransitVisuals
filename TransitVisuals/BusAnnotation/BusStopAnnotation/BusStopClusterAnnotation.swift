//
//  BusStopClusterAnnotation.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2023-01-10.
//

import MapKit

/// - Tag: ClusterAnnotationView
class ClusterAnnotationView: MKAnnotationView {
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        collisionMode = .circle
        centerOffset = CGPoint(x: 0, y: -10) // Offset center point to animate better with marker annotations
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// - Tag: CustomCluster
    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultLow
        image = MKBusStopAnnotationView.drawBusBackGround()
        let background2 = UIImageView(image: MKBusStopAnnotationView.drawBusBackGround())
        background2.frame = background2.frame.offsetBy(dx: 2, dy: 0)
        background2.tintColor = UIColor(red: 0.32, green: 0.51, blue: 0.68, alpha: 1.00)
        let bus1 = MKBusStopAnnotationView.getBusIcon()
        let bus2 = MKBusStopAnnotationView.getBusIcon()
        bus2.frame = bus2.frame.offsetBy(dx: 2, dy: 0)
        addSubview(background2)
        addSubview(bus1)
        addSubview(bus2)
        canShowCallout = true
    }
}
