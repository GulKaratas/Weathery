import Foundation


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

struct WeeklyWeatherData: Codable {
    let daily: [DailyWeather]
}

struct DailyWeather: Codable {
    let dt: Int
    let temp: Temp
    let weather: [Weather]
    
    struct Temp: Codable {
        let day: Double
    }
    
    struct Weather: Codable {
        let icon: String
        let description: String
    }
}

// Hava kalitesi verilerini modellemek için yapılar
struct AirQuality: Codable {
    let list: [AirQualityData]
}

struct AirQualityData: Codable {
    let main: MainPollution
}

struct MainPollution: Codable {
    let aqi: Int // Hava Kalitesi İndeksi
}

// Hava durumu ve hava kalitesi verilerini yöneten sınıf
struct WeatherManager {
    // OpenWeatherMap API URL (API_KEY kendi anahtarınızla değiştirilmelidir)
    let weatherURL = "https://api.openweathermap.org/data/2.5/forecast?lat={lat}&lon={lon}&appid=2bdf7ae26311d6b4029bfe9b2e71ce74&units=metric"
    let weeklyWeatherURL = "https://api.openweathermap.org/data/2.5/onecall?lat={lat}&lon={lon}&exclude=hourly,minutely&appid=2bdf7ae26311d6b4029bfe9b2e71ce74&units=metric"


    // Hava durumu verilerini getiren fonksiyon
    func fetchWeather(lat: Double, lon: Double) async throws -> [HourlyWeather] {
        let urlString = weatherURL.replacingOccurrences(of: "{lat}", with: String(lat)).replacingOccurrences(of: "{lon}", with: String(lon))
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
        return weatherData.list
    }
    
    // Haftalık hava durumu verilerini getiren fonksiyon
    func fetchWeeklyWeather(lat: Double, lon: Double) async throws -> [DailyWeather] {
        let urlString = weeklyWeatherURL.replacingOccurrences(of: "{lat}", with: String(lat)).replacingOccurrences(of: "{lon}", with: String(lon))
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "No data"
            print("Error: \(httpResponse.statusCode) - \(errorMessage)")
            throw URLError(.badServerResponse)
        }
       

        let weeklyWeatherData = try JSONDecoder().decode(WeeklyWeatherData.self, from: data)
        return weeklyWeatherData.daily
    }

    // Hava kalitesi verilerini getiren fonksiyon
    func fetchAirQuality(lat: Double, lon: Double) async throws -> AirQuality {
        let apiKey = "2bdf7ae26311d6b4029bfe9b2e71ce74"
        print("Hava kalitesi için lat: \(lat), lon: \(lon)") // Hata ayıklama çıktısı
        let urlString = "https://api.openweathermap.org/data/2.5/air_pollution?lat=\(lat)&lon=\(lon)&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])
        }

        // URLSession'dan veri ve yanıt alın
        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))

        // Yanıtın içeriğini yazdırın
        print(String(data: data, encoding: .utf8) ?? "Veri yok")


        // Yanıtı HTTPURLResponse olarak kontrol edin
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Yanıt geçersiz"])
        }

        // HTTP yanıt durumunu kontrol edin
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Veri yok"
            print("Hava kalitesi alırken hata: \(httpResponse.statusCode) - \(errorMessage)") // Hata ayıklama çıktısı
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Hava kalitesi verisi alırken hata"])
        }

        // JSON verisini çözümleyin
        let airQuality = try JSONDecoder().decode(AirQuality.self, from: data)
        return airQuality
    }


}
