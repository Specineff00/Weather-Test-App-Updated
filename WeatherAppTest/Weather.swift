//
//  Weather.swift
//  WeatherAppTest
//
//  Created by Yogesh N Ramsorrrun on 14/12/2016.
//  Copyright © 2016 Yogesh N Ramsorrrun. All rights reserved.
//

import Foundation

struct Weather {
    
    let date: Date
    let currentWeather: String
    let temp: Float
    let windSpeed: Float
    let windDirection: String
    let windDegrees: Float
    
    init(date: String, currentWeather: String, tempK: Float, windDegrees: Float, windSpeed: Float) { //Check values
        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.date = dateFormatter.date(from: date)!
        self.currentWeather = currentWeather
        self.temp = tempK - 273.15
        self.windDegrees = windDegrees
        self.windSpeed = (windSpeed * 3600)/1609.3
        
        switch windDegrees { //Figures out direction.
        case 0..<22.5:
            self.windDirection = "North"
        case 22.5..<67.5:
            self.windDirection = "North East"
        case 67.5..<112.5:
            self.windDirection = "East"
        case 112.5..<157.5:
            self.windDirection = "South East"
        case 157.5..<202.5:
            self.windDirection = "South"
        case 202.5..<247.5:
            self.windDirection = "South West"
        case 247.5..<292.5:
            self.windDirection = "West"
        case 292.5..<337.5:
            self.windDirection = "North West"
        case 337.5..<360:
            self.windDirection = "North"
        default:
            self.windDirection = "Unknown"
        }
    }
    
    
}
