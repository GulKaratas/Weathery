//
//  WeatheryTests.swift
//  WeatheryTests
//
//  Created by Gül Karataş on 22.10.2024.
//

import XCTest
@testable import Weathery

final class WeatheryTests: XCTestCase {
    
    var weatherManager: WeatherManager!
    
    override func setUpWithError() throws {
        // Initialize the WeatherManager before each test
        weatherManager = WeatherManager()
    }

    override func tearDownWithError() throws {
        // Clean up after each test
        weatherManager = nil
    }

    func testFetchWeather() async throws {
        // This test should mock the response from OpenWeather API
        let lat = 37.7749
        let lon = -122.4194
        
        // You may want to use a mocking library or method to simulate a response here.
        // For now, we'll call the actual function which will fail if there's no internet.
        do {
            let weatherData = try await weatherManager.fetchWeather(lat: lat, lon: lon)
            XCTAssertNotNil(weatherData)
            XCTAssertFalse(weatherData.isEmpty)
            // Check properties of the returned weather data
            let firstWeather = weatherData[0]
            XCTAssertEqual(firstWeather.main.temp, Double(Int(firstWeather.main.temp))) // Example of checking temp format
        } catch {
            XCTFail("Fetching weather data failed with error: \(error)")
        }
    }
    
    func testFetchWeeklyWeather() async throws {
        // This test should also mock the response from OpenWeather API
        let lat = 37.7749
        let lon = -122.4194
        
        do {
            let weeklyWeatherData = try await weatherManager.fetchWeeklyWeather(lat: lat, lon: lon)
            XCTAssertNotNil(weeklyWeatherData)
            XCTAssertFalse(weeklyWeatherData.isEmpty)
            // Check properties of the returned weekly weather data
            let firstDailyWeather = weeklyWeatherData[0]
            XCTAssertEqual(firstDailyWeather.temp.day, Double(Int(firstDailyWeather.temp.day))) // Example of checking day's temp format
        } catch {
            XCTFail("Fetching weekly weather data failed with error: \(error)")
        }
    }

    func testFetchAirQuality() async throws {
        // This test should also mock the response from OpenWeather API
        let lat = 37.7749
        let lon = -122.4194
        
        do {
            let airQualityData = try await weatherManager.fetchAirQuality(lat: lat, lon: lon)
            XCTAssertNotNil(airQualityData)
            XCTAssertFalse(airQualityData.list.isEmpty)
            // Check properties of the returned air quality data
            let firstAirQuality = airQualityData.list[0]
            XCTAssertEqual(firstAirQuality.main.aqi, Int(firstAirQuality.main.aqi)) // Example of checking aqi format
        } catch {
            XCTFail("Fetching air quality data failed with error: \(error)")
        }
    }
    
    func testExample() throws {
        // Example functional test case
        XCTAssertTrue(true) // Replace with meaningful test
    }

    func testPerformanceExample() throws {
        // Example performance test case
        self.measure {
            // Measure the time of some code
        }
    }
}
