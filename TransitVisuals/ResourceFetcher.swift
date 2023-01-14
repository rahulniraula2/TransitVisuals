//
//  ResourceFetcher.swift
//  TransitVisuals
//
//  Created by Rahul Niraula on 2022-08-10.
//

import UIKit
import MapKit
import SwiftProtobuf
import SwiftCSV
import ZIPFoundation

extension ViewController {
    
    func showLoadingScreen() -> UIAlertController{
        let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating();
        alert.view.addSubview(loadingIndicator)
        DispatchQueue.main.async {
            self.present(alert, animated: false)
        }
        return alert
    }
}
