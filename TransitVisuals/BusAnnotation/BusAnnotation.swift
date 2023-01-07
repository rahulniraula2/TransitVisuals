//
//  BusAnnotation.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2022-08-10.
//

import Foundation
import UIKit
import MapKit

class BusAnnotation: UIView {
    
   
    @IBOutlet weak var busIcon: UIImageView!
    @IBOutlet weak var busNumberLabel: UILabel!
    @IBOutlet weak var backgroundLayer: UIView!
    @IBOutlet weak var triangle: UIImageView!
    
    @IBOutlet weak var xConstraint: NSLayoutConstraint!
    @IBOutlet weak var yConstraint: NSLayoutConstraint!
    
    var kvoToken: NSKeyValueObservation?
    
    func observe(_ annotation: BusPointAnnotation) {
        //if let annotation = annotation{
        self.kvoToken = annotation.observe(\.bearing, options: .new, changeHandler: { observedAnotation, change in
                if let newVal = change.newValue {
                    self.rotateTriangle(newVal)
                }
            })
        //}
    }
    
    deinit {
            kvoToken?.invalidate()
    }
    
        
    /*
        deinit {
            removeObserverIfAny()
        }

        

        func showInformation() {
            addSubview(informationLabel)
        }

        func hideInformation() {
            informationLabel.removeFromSuperview()
        }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            guard context == &observerContext else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
                return
            }

            if let annotation = annotation as? MyAnnotation, let information = annotation.information {
                informationLabel.text = information
            }
        }
     */
    
    /*override init(annotation: MKAnnotation?, reuseIdentifier: String?){
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }*/
    
    func rotateTriangle(_ bearing: CGFloat){
        let xOffSet: CGFloat = CGFloat(cos(bearing) * 16.5)
        let yOffSet: CGFloat = CGFloat(sin(bearing) * 16.5)
        self.xConstraint.constant = xOffSet
        self.yConstraint.constant = yOffSet
        self.triangle.transform = .identity
        self.triangle.transform = (self.triangle.transform.rotated(by: CGFloat(bearing + .pi/2)))
        self.layoutIfNeeded()
    }
    
    
}

