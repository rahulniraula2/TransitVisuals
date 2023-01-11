//
//  BusStopAnnotationView.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2023-01-10.
//
import UIKit
import MapKit

class BusStopAnnotationView: UIView {
    
    @IBOutlet weak var backgroundView: UIView!
    
    override public func awakeFromNib() {
        super.awakeFromNib();
        self.backgroundView.layer.cornerRadius = 5
    }
}

class MKBusStopAnnotationView: MKAnnotationView {
    
    static let ReuseID = "BusStopAnnotation"
    
    /// - Tag: ClusterIdentifier
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "BusStopAnnotation"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultLow
        image = MKBusStopAnnotationView.drawBusBackGround()
        let busView = MKBusStopAnnotationView.getBusIcon()
        addSubview(busView)
        canShowCallout = true
    }
    
    static func getBusIcon() -> UIImageView {
        var imageView = UIImageView()
        imageView.image = UIImage(systemName: "bus.fill")
        imageView.frame = CGRect(x: 1.5, y: 1.5, width: 7, height: 7)
        imageView.tintColor = .white
        imageView.clipsToBounds = true
        return imageView
    }
    
    static func drawBusBackGround() -> UIImage{
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        return renderer.image { _ in
            let backgroundColor = UIColor(red: 0.27, green: 0.42, blue: 0.68, alpha: 1.00)
            backgroundColor.setFill()
            let rect = CGRect(x: 0, y: 0, width: 10, height: 10)
            UIBezierPath(roundedRect: rect, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 2, height: 2)).fill()
        }
    }
}
