//
//  WeatherManager.swift
//  Weathery
//
//  Created by Gül Karataş on 24.10.2024.
//

import Foundation

// OpenWeatherMap API'den gelen JSON verisini modellemek için yapılar
struct WeatherData: Codable {
    let list: [HourlyWeather]
}

struct HourlyWeather: Codable {
    let dt: Int
    let main: Main
    let weather: [Weather]
    
    struct Main: Codable {
        let temp: Double
    }
    
    struct Weather: Codable {
        let icon: String
        let description: String
    }
}

struct WeatherManager {
    // OpenWeatherMap API URL (API_KEY kendi anahtarınızla değiştirilmelidir)
    let weatherURL = "https://api.openweathermap.org/data/2.5/forecast?lat={lat}&lon={lon}&appid=2bdf7ae26311d6b4029bfe9b2e71ce74&units=metric"
    
    // Hava durumu verilerini getiren fonksiyon
    func fetchWeather(lat: Double, lon: Double) async throws -> [HourlyWeather] {
        // URL'yi oluştur
        let urlString = weatherURL.replacingOccurrences(of: "{lat}", with: String(lat)).replacingOccurrences(of: "{lon}", with: String(lon))
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)  // URL geçersizse hata döndür
        }
       

        // Veriyi çek (asenkron)
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = response as? HTTPURLResponse
        
        // Yanıt kodunu kontrol et
        print("HTTP Yanıt Kodu: \(httpResponse?.statusCode ?? 0)")
        
        // API yanıtını yazdır
        if let responseData = String(data: data, encoding: .utf8) {
            print("API Yanıtı: \(responseData)")
        }

        // HTTP yanıtını kontrol et
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)  // Sunucudan hatalı yanıt
        }

        // JSON verisini çözümle
        let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
        
        // Saatlik hava durumu listesini döndür
        return weatherData.list
    }
}
