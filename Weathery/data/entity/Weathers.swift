//
//  Weathers.swift
//  Weathery
//
//  Created by Gül Karataş on 23.10.2024.
//

import Foundation

class Weathers {
   
    var id : Int?
    var cityName : String?
    var airName : String?
    var degree : Int?
    
    
    init() {
        
    }
    
    init(id: Int, cityName: String, airName: String, degree: Int) {
        self.id = id
        self.cityName = cityName
        self.airName = airName
        self.degree = degree
    }
    
}
