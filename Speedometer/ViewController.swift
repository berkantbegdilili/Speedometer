//
//  ViewController.swift
//  Speedometer
//
//  Created by Berkant Beğdilili on 21.05.2020.
//  Copyright © 2020 Berkant Beğdilili. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import MBCircularProgressBar


class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var progressBar: MBCircularProgressBarView!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var zoom: UIStepper!
    
    // Info View
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var mapType: UISegmentedControl!
    @IBOutlet weak var conversions: UISegmentedControl!
    @IBOutlet weak var maxSpeed: UITextField!
    //
    
    let defaults = UserDefaults.standard
    let locationManager = CLLocationManager()
    var authorizationStatus:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startLocation()
    }
    
    
    @IBAction func infoButton(_ sender: Any) {
        UIView.animate(withDuration: 1.5, animations: {
            self.infoView.isHidden = false
            self.progressBar.isHidden = true
            self.zoom.isHidden = true
            
            self.maxSpeed.delegate = self
            self.maxSpeed.setupToolbar()
        })
    }
    
    @IBAction func infoViewIsHidden(_ sender: Any) {
        UIView.animate(withDuration: 1.5, animations: {
            self.infoView.isHidden = true
            self.progressBar.isHidden = false
            self.zoom.isHidden = false
        })
    }
    
    @IBAction func mapTypeIndexChanged(_ sender: Any) {
        switch mapType.selectedSegmentIndex {
            case 0 :
                defaults.set(0, forKey: "mapType")
                
            case 1 :
                defaults.set(1, forKey: "mapType")
            case 2 :
                defaults.set(2, forKey: "mapType")
            default :
                break
        }
    }
    
    @IBAction func conversionIndexChanged(_ sender: Any) {
        switch conversions.selectedSegmentIndex {
            case 0 :
                defaults.set(0, forKey: "conversions")
            case 1 :
                defaults.set(1, forKey: "conversions")
            default :
                break
        }
    }
    
    func setupLocation(){
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        progressBar.unitString = ""
    }
    
    func startLocation(){
        if authorizationStatus{
            locationManager.startUpdatingLocation()
            progressBar.isHidden = false
        }else{
            dismiss(animated: true, completion: nil)
            
            let alert = UIAlertController.init(title: "Could Not Reach Location",
                                               message: "Please Open Location Service!",
                                               preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Allow Once Using Location",
                                          style: .default)
                                          { alert -> Void in
                                            self.locationManager(self.locationManager, didChangeAuthorization: .authorizedWhenInUse)
                                            self.startLocation()
                                          })
            
            
            alert.addAction(UIAlertAction(title: "Exit",
                                          style: .destructive,
                                          handler: nil))
            
            
            self.present(alert,
                         animated: true,
                         completion: nil)
        }
        
    }
}



extension ViewController: CLLocationManagerDelegate,UITextFieldDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[locations.count-1]
        
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
       
        let camera = MKMapCamera(lookingAtCenter: location.coordinate , fromEyeCoordinate: location.coordinate, eyeAltitude: location.altitude)
        
        let zoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: zoom.value ,maxCenterCoordinateDistance: zoom.maximumValue)
        
        mapView.setCameraBoundary(MKMapView.CameraBoundary(coordinateRegion: region), animated: true)
        mapView.setCamera(camera, animated: true)
        mapView.setCameraZoomRange(zoomRange, animated: true)
        
        mapView.showsUserLocation = true
       
        
        UIView.animate(withDuration: 1, animations: {
            
    
            switch self.defaults.integer(forKey: "conversions"){
                case 0:
                    let kmh = location.speed*3.6
                    self.progressBar.value = CGFloat(kmh)
                    self.progressBar.unitString = " km/h"
                    self.conversions.selectedSegmentIndex = 0
                case 1:
                    let mph = location.speed*2.2369362920544025
                    self.progressBar.value = CGFloat(mph)
                    self.progressBar.unitString = " mp/h"
                    self.conversions.selectedSegmentIndex = 1
                default:
                    break
            }
            
            
            switch self.defaults.integer(forKey: "mapType"){
                case 0 :
                    self.mapView.mapType = .standard
                    self.mapType.selectedSegmentIndex = 0
                    self.progressBar.fontColor = UIColor.label
                    self.infoButton.tintColor = UIColor.label
                case 1 :
                    self.mapView.mapType = .satellite
                    self.mapType.selectedSegmentIndex = 1
                    self.infoButton.tintColor = UIColor.white
                    self.progressBar.fontColor = UIColor.white
                case 2 :
                    self.mapView.mapType = .hybrid
                    self.mapType.selectedSegmentIndex = 2
                    self.infoButton.tintColor = UIColor.white
                    self.progressBar.fontColor = UIColor.white
                default:
                    break
            }
            
            
            UIView.animate(withDuration: 2.5, animations: {
                if self.progressBar.value < 70 {
                    self.progressBar.progressColor = UIColor.systemGreen
                    self.progressBar.progressStrokeColor = UIColor.systemGreen
                    
                }else if self.progressBar.value < 120{
                    self.progressBar.progressColor = UIColor.systemYellow
                    self.progressBar.progressStrokeColor = UIColor.systemYellow
                }else{
                    self.progressBar.progressColor = UIColor.systemRed
                    self.progressBar.progressStrokeColor = UIColor.systemRed
                }
            })
            
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied{
            authorizationStatus = false
        }else {
            authorizationStatus = true
        }
    }
    
    // Max Speed Ayarı
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let maxSpeed = NumberFormatter().number(from: textField.text!) else { return }
        self.progressBar.maxValue = CGFloat(truncating: maxSpeed)
    }
    
}

extension UITextField {
    func setupToolbar() {
        
        let screenWidth = UIScreen.main.bounds.width
        
        let toolBar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: screenWidth, height: 45.0))
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancel = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: #selector(keyboardIsHidden))
        cancel.tintColor = UIColor.init(displayP3Red: 0.543973, green: 0.127511, blue: 0.10608, alpha: 1)
        let barButton = UIBarButtonItem(title: "Done", style: .plain, target: nil, action: #selector(keyboardIsHidden))
        toolBar.setItems([cancel, flexible, barButton], animated: false)
        self.inputAccessoryView = toolBar
    }
    
    @objc func keyboardIsHidden() {
        self.resignFirstResponder()
    }
    
}
