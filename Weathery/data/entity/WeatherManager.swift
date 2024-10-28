import Foundation

// Hava durumu verilerini modellemek için yapılar
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

// Haftalık hava durumu verilerini modellemek için yapılar
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
struct AirQualityData: Codable {
    let list: [AirQualityList]

    struct AirQualityList: Codable {
        let main: MainPollution
        let components: Components
        let dt: Int

        struct MainPollution: Codable {
            let aqi: Int // Air Quality Index
        }

        struct Components: Codable {
            let co: Double
            let no: Double
            let no2: Double
            let o3: Double
            let so2: Double
            let pm2_5: Double
            let pm10: Double
            let nh3: Double
        }
    }
}

// Hava durumu ve hava kalitesi verilerini yöneten sınıf
struct WeatherManager {
    let apiKey = "b01cd30abbdb6bb286ae3ec6dfb6d7eb"
    
    // Günlük hava durumu tahmini
    let weeklyWeatherURL = "https://api.openweathermap.org/data/2.5/onecall?lat={lat}&lon={lon}&exclude=hourly,minutely&appid={apiKey}&units=metric"
    
    // Hava durumu verilerini getiren fonksiyon
    func fetchWeather(lat: Double, lon: Double) async throws -> [HourlyWeather] {
        let urlString = "https://api.openweathermap.org/data/2.5/forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            if httpResponse.statusCode == 200 {
                let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
                return weatherData.list
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Veri yok"
                print("Günlük hava durumu alırken hata: \(httpResponse.statusCode) - \(errorMessage)")
                throw URLError(.badServerResponse)
            }
        } catch {
            print("Günlük hava durumu alırken hata: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Haftalık hava durumu verilerini getiren fonksiyon
    func fetchWeeklyWeather(lat: Double, lon: Double) async throws -> [DailyWeather] {
        let urlString = weeklyWeatherURL
            .replacingOccurrences(of: "{lat}", with: String(lat))
            .replacingOccurrences(of: "{lon}", with: String(lon))
            .replacingOccurrences(of: "{apiKey}", with: apiKey)
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            if httpResponse.statusCode == 200 {
                let weeklyWeatherData = try JSONDecoder().decode(WeeklyWeatherData.self, from: data)
                return weeklyWeatherData.daily
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Veri yok"
                print("Haftalık hava durumu alırken hata: \(httpResponse.statusCode) - \(errorMessage)")
                throw URLError(.badServerResponse)
            }
        } catch {
            print("Haftalık hava durumu alırken hata: \(error.localizedDescription)")
            throw error
        }
    }

    // Hava kalitesi verilerini getiren fonksiyon
    func fetchAirQuality(lat: Double, lon: Double) async throws -> AirQualityData {
        let urlString = "https://api.openweathermap.org/data/2.5/air_pollution?lat=\(lat)&lon=\(lon)&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Yanıt geçersiz"])
            }

            if httpResponse.statusCode == 200 {
                let airQuality = try JSONDecoder().decode(AirQualityData.self, from: data)
                return airQuality
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Veri yok"
                print("Hava kalitesi alırken hata: \(httpResponse.statusCode) - \(errorMessage)")
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Hava kalitesi verisi alırken hata: \(errorMessage)"])
            }
        } catch {
            print("Hava kalitesi alırken hata: \(error.localizedDescription)")
            throw error
        }
    }
}
