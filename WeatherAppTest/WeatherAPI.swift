//
//  WeatherAPI.swift
//  WeatherAppTest
//
//  Created by Yogesh N Ramsorrrun on 14/12/2016.
//  Copyright © 2016 Yogesh N Ramsorrrun. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

protocol updateViewsDelegate: class {
    
    func updateViews(weather: Weather, newData: Bool)
    func startIndicatorSpinning()
    func stopIndicatorSpinning()
}

class WeatherAPI {
    
    var weatherList = [Weather]()
    var lastUpdated: String?
    weak var delegate: updateViewsDelegate?
    private var url = "http://api.openweathermap.org/data/2.5/forecast?"
    private let apiKey = "&APPID=647678073c16521ba851dd2428e07a1b"
    private var jsonData: JSON?
    
    
    func communicateWithAPI(latitude: Float, longitude: Float) {
        
        let latitudeString = String(format:"%.2f", latitude)
        let longitudeString = String(format:"%.2f", longitude)
        let requestUrl: String = ("\(url)lat=\(latitudeString)&lon=\(longitudeString)\(apiKey)")
        self.delegate?.startIndicatorSpinning()
        Alamofire.request(requestUrl).responseJSON { response -> Void in
            
            if(response.result.error != nil) {
                print("GET Error: \(response.result.error)")
            } else {
                self.jsonData = JSON(response.result.value!)
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                self.lastUpdated = dateFormatter.string(from: Date())
                self.prepareWeatherData()
                self.delegate?.updateViews(weather: self.weatherList[0], newData: true)
                self.delegate?.stopIndicatorSpinning()
            }
        }
    }
    
    func prepareWeatherData() {
        
        weatherList.removeAll()
        guard let _ = jsonData?["list"].count else {
            print("No Data")
            return
        }
        
        for index in 0...7 { //Produce 8 items for weatherList Array from JSON
            
            if let date = jsonData!["list"][index]["dt_txt"].string,
                let currentWeather = jsonData!["list"][index]["weather"][0]["main"].string,
                let tempK = jsonData!["list"][index]["main"]["temp"].float,
                let windDegrees = jsonData!["list"][index]["wind"]["deg"].float,
                let windSpeed = jsonData!["list"][index]["wind"]["speed"].float {
                
                let weather = Weather(date: date, currentWeather: currentWeather, tempK: tempK, windDegrees: windDegrees, windSpeed: windSpeed)
                
                self.weatherList.append(weather)
            }
        }
    }
}
