//
//  ViewController.swift
//  Weathery
//
//  Created by Gül Karataş on 22.10.2024.
//

import UIKit
import CoreLocation

class Weather: UIViewController , CLLocationManagerDelegate{

    @IBOutlet weak var airLabel: UILabel!
    @IBOutlet weak var degreeLabel: NSLayoutConstraint!
    @IBOutlet weak var cityLabel: UILabel!
    
    var weather = Weathers()
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func alert(title : String , message : String) {
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        var action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
}

