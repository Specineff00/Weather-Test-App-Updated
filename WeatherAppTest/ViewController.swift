//
//  ViewController.swift
//  WeatherAppTest
//
//  Created by Yogesh N Ramsorrrun on 14/12/2016.
//  Copyright © 2016 Yogesh N Ramsorrrun. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import MapKit
import Alamofire
import SwiftyJSON
import ReachabilitySwift

class ViewController: UIViewController, CLLocationManagerDelegate, updateViewsDelegate {
    @IBOutlet weak var currentConditionLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var windSpeedLabel: UILabel!
    @IBOutlet weak var windDirectionLabel: UILabel!
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    let weatherAPI = WeatherAPI()
    var weatherNow: Weather?
    let locationManager = CLLocationManager()
    var longitude: Float?
    var latitude: Float?
    var weatherList: [Weather] = []
    var weathers: [NSManagedObject] = []
    var alert: UIAlertController?
    var reachability = Reachability()!

    override func viewDidLoad() {
        super.viewDidLoad()
        weatherAPI.delegate = self
        
        //Core Data Load
        coreDataLoad()
        offlineCacheLoad() //Populate labels before new data from API is received if there is data saved and within time limit
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = isOfflineCheck()
    }
    
    func updateViews(weather: Weather, newData: Bool) {
        
        if newData == true { //Clear Core Data and save if theres new data
            deleteCoreData()
            for item in weatherAPI.weatherList { //Save to Core Data
                save(weather: item)
            }
        }
        weatherNow = weather
        currentConditionLabel.text = weather.currentWeather
        temperatureLabel.text = String(format: "%.2f\u{00B0}c", weather.temp)
        windSpeedLabel.text = String(format:"%.2fmph",weather.windSpeed)
        windDirectionLabel.text = weather.windDirection
        lastUpdatedLabel.text = weatherAPI.lastUpdated
    }
    
    func offlineCacheLoad() {
        
        func noCacheDataAlert() {
            let alert: UIAlertController = UIAlertController(title: "No Data!", message: "Check your connection and refresh", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true) {action in _ = self.isOfflineCheck() }
        }
        
        guard weatherList.count > 0 else { //Check for entries loaded from Core Data
            print("No Offline Cache Data")
            noCacheDataAlert()
            return
        }
        let calender = Calendar.current
        let now = Date()
        for item in weatherList {
            var components = calender.dateComponents([Calendar.Component.second], from: item.date, to: now)
            if  components.second! < -84600 { //Check for 24 hours passing
                deleteCoreData()
                noCacheDataAlert()
            }
            if  (-10800)...0 ~= components.second! { //Check for the closest weather item
                updateViews(weather: item, newData: false)
            }
        }
    }
    
    @IBAction func refreshWeather(_ sender: Any) {
        
        //Check for location Data and online status
        guard (isOfflineCheck() == false) && (locationCheck() == true)  else {
            return
        }
        weatherAPI.communicateWithAPI(latitude: latitude!, longitude: longitude!)
    }
    

    //MARK: - Connectivity Check Functions
    
    func isOfflineCheck() -> Bool {

        guard reachability.isReachableViaWWAN || reachability.isReachableViaWiFi  else {
            alert = UIAlertController(title: "You're offline!", message: "Check your connection", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            self.alert?.addAction(okAction)
            self.present(self.alert!, animated: true, completion: { 
                self.stopIndicatorSpinning()
            })
            
            return true
        }
        return false
    }
    
    func locationCheck() -> Bool {
        guard let _ = latitude, //Check for existence of lat and lon values
            let _ = longitude else {return false
        }
        return true
    }
    
    //MARK:- Core Location Functions
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard reachability.isReachableViaWWAN == false || reachability.isReachableViaWiFi == false else {
            return
        }
        let userLocation:CLLocation = locations[0]
        if longitude == nil && latitude == nil {
            longitude = Float(userLocation.coordinate.longitude)
            latitude = Float(userLocation.coordinate.latitude)
            weatherAPI.communicateWithAPI(latitude: latitude!, longitude: longitude!)
        } else {
            longitude = Float(userLocation.coordinate.longitude)
            latitude = Float(userLocation.coordinate.latitude)
        }
    }
    
    // MARK: - Core Data functions
    
    func coreDataLoad() {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Weathers")
        do {
            weathers = try managedContext.fetch(fetchRequest)
            if weathers.count == 0 { //***Check for Core Data fetch result***
                print("No data to Load")
                return
            }
            weatherAPI.lastUpdated = weathers[0].value(forKeyPath: "lastUpdated") as? String
            weatherList.removeAll()
            for item in weathers {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let date = item.value(forKeyPath: "date") as? Date
                let dateString = dateFormatter.string(from: date!)
                let currentWeather = item.value(forKeyPath: "currentWeather") as? String
                let temp = item.value(forKeyPath: "temperature") as? Float
                let tempK = temp! + 273.15
                let windDegrees = item.value(forKeyPath: "windDegrees") as? Float
                let windSpeed = item.value(forKeyPath: "windSpeed") as? Float
                let weather = Weather(date: dateString, currentWeather: currentWeather!, tempK: tempK, windDegrees: windDegrees!, windSpeed: windSpeed!)
                weatherList.append(weather)
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
    }
    
    func save(weather: Weather) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Weathers",
                                                in: managedContext)!
        let weatherManagedObject = NSManagedObject(entity: entity,
                                     insertInto: managedContext)
        
        weatherManagedObject.setValue(weather.date, forKeyPath: "date")
        weatherManagedObject.setValue(weather.currentWeather, forKeyPath: "currentWeather")
        weatherManagedObject.setValue(weather.temp, forKeyPath: "temperature")
        weatherManagedObject.setValue(weather.windDegrees, forKeyPath: "windDegrees")
        weatherManagedObject.setValue(weather.windSpeed, forKeyPath: "windSpeed")
        weatherManagedObject.setValue(weatherAPI.lastUpdated, forKeyPath: "lastUpdated")
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func deleteCoreData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Weathers")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        let managedContext = appDelegate.persistentContainer.viewContext
        do {
            try managedContext.execute(batchDeleteRequest)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    //MARK: - Activity Indicator Functions
    
    func startIndicatorSpinning() {
        activityIndicatorView.startAnimating()
    }
    func stopIndicatorSpinning() {
        activityIndicatorView.stopAnimating()
    }
}

