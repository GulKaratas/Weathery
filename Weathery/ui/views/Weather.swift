import UIKit
import CoreLocation

class Weather: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var airLabel: UILabel!
    @IBOutlet weak var weatherTableView: UITableView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var degreeLabel: UILabel!
    @IBOutlet weak var weatherCollectionView: UICollectionView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!

    var locationManager: CLLocationManager!
    var weatherManager = WeatherManager()
    var hourlyWeatherData: [HourlyWeather] = []
    var dailyWeatherData: [DailyWeather] = []
    var selectedCity: String?
    
    let airQualityProperties = [
        ("Hava Kalitesi İndeksi (AQI)", "AQI: "),
        ("Rüzgar Hızı", "Rüzgar Hızı: "),
        ("Karbonmonoksit (CO)", "CO: "),
        ("Azot Dioksit (NO2)", "NO2: "),
        ("Ozon (O3)", "O3: "),
        ("Partikül Madde 10 (PM10)", "PM10: "),
        ("Partikül Madde 2.5 (PM2.5)", "PM2.5: "),
        ("Kükürt Dioksit (SO2)", "SO2: ")
    ]

    
    // Hava kalitesi verilerini yöneten bir yapı oluşturun
    var airQualityData: AirQualityData?

    private let defaultIcon = "defaultIcon"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSegmentedControl()
        setupLocationManager()
        
        print("Seçilen şehir: \(selectedCity ?? "Şehir Seçilmedi")") // Debugging output
        cityLabel.text = selectedCity ?? "Şehir Seçilmedi"  // Şehir etiketi burada güncelleniyor.
        
        weatherCollectionView.delegate = self
        weatherCollectionView.dataSource = self
        
        weatherTableView.delegate = self
        weatherTableView.dataSource = self
        
        weatherTableView.separatorColor = UIColor(named: "Background")
        
        if let selectedCity = selectedCity {
                Task {
                    do {
                        let coordinates = try await fetchCoordinates(for: selectedCity)
                        try await fetchWeatherData(for: coordinates.lat, lon: coordinates.lon)
                        try await fetchAirQualityData(lat: coordinates.lat, lon: coordinates.lon)
                    } catch {
                        print("Hata: \(error.localizedDescription)")
                    }
                }
            }
        if let layout = weatherCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal // Horizontal scrolling
            layout.minimumLineSpacing = 10 // Spacing between cells
            layout.itemSize = CGSize(width: view.bounds.width * 0.8, height: view.bounds.height * 0.5) // Dynamic cell size
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedCity = selectedCity {
            Task {
                do {
                    let coordinates = try await fetchCoordinates(for: selectedCity)
                    try await fetchWeatherData(for: coordinates.lat, lon: coordinates.lon)
                    
                    DispatchQueue.main.async {
                        self.weatherTableView.reloadData() // Tabloyu güncelleyerek yeni veriyi gösterin
                    }
                } catch {
                    print("Hata: \(error.localizedDescription)")
                }
            }
        }
    }


    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let layout = weatherCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 10
            layout.itemSize = CGSize(width: weatherCollectionView.frame.width * 0.8, height: weatherCollectionView.frame.height * 0.5)
        }
    }
    func updateCityLabel() {
        DispatchQueue.main.async {
            self.cityLabel.text = self.selectedCity ?? "Şehir Seçilmedi"
        }
    }
    
    

    func fetchWeatherData(for lat: Double, lon: Double) async throws {
           hourlyWeatherData = try await weatherManager.fetchWeather(lat: lat, lon: lon)

           // Update the UI on the main thread
           DispatchQueue.main.async {
               if let temp = self.hourlyWeatherData.first?.main.temp {
                   self.degreeLabel.text = "\(Int(temp)) °"
               }
               self.updateCityLabel()
               // Update other UI components as needed
               self.weatherCollectionView.reloadData()
           }
       }

    func fetchCoordinates(for cityName: String) async throws -> (lat: Double, lon: Double) {
        let apiKey = "2bdf7ae26311d6b4029bfe9b2e71ce74" // Replace with your OpenWeatherMap API key
        let encodedCityName = cityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(encodedCityName)&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        if let coord = json?["coord"] as? [String: Double],
           let lat = coord["lat"], let lon = coord["lon"] {
            return (lat, lon)
        } else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not get coordinates"])
        }
    }

    @IBAction func segmentedControlChanged(_ sender: UISegmentedControl) {
        Task {
            // Initialize lat and lon with default values
            var lat: Double = 0
            var lon: Double = 0
            
            if let selectedCity = selectedCity {
                // If a city is selected, fetch weather data for that city
                do {
                    let coordinates = try await fetchCoordinates(for: selectedCity)
                    lat = coordinates.lat
                    lon = coordinates.lon
                } catch {
                    print("Error fetching coordinates for selected city: \(error.localizedDescription)")
                    return // Exit early if there is an error
                }
            } else {
                // Use the current location if no city is selected
                if let location = locationManager.location {
                    lat = location.coordinate.latitude
                    lon = location.coordinate.longitude
                } else {
                    print("Current location is not available.")
                    return // Exit if location is not available
                }
            }
            
            switch sender.selectedSegmentIndex {
            case 0:
                // Saatlik hava verisi
                do {
                    self.hourlyWeatherData = try await weatherManager.fetchWeather(lat: lat, lon: lon)
                    DispatchQueue.main.async {
                        self.degreeLabel.text = "\(Int(self.hourlyWeatherData.first?.main.temp ?? 0)) °"
                        self.updateUIForCurrentDay()
                        self.weatherCollectionView.reloadData()
                    }
                } catch {
                    print("Error fetching hourly weather data: \(error.localizedDescription)")
                }
            case 1:
                // Günlük hava verisi (haftalık)
                do {
                    self.dailyWeatherData = try await weatherManager.fetchWeeklyWeather(lat: lat, lon: lon)
                    // Yalnızca ilk 7 günü almak için kesme
                    self.dailyWeatherData = Array(self.dailyWeatherData.prefix(7))
                    DispatchQueue.main.async {
                        self.weatherCollectionView.reloadData()
                    }
                } catch {
                    print("Error fetching weekly weather data: \(error.localizedDescription)")
                }
            default:
                break
            }
        }
    }


    func setupSegmentedControl() {
        segmentedControl.backgroundColor = .clear
        segmentedControl.selectedSegmentTintColor = UIColor(named: "BorderColor")
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .selected)
        segmentedControl.layer.borderColor = UIColor(named: "BorderColor")?.cgColor
        segmentedControl.layer.borderWidth = 1
        segmentedControl.layer.cornerRadius = 10
        segmentedControl.clipsToBounds = true
    }

    func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationAuthorization()
    }

    func iconURL(iconName: String) -> URL? {
        let baseURL = "https://openweathermap.org/img/wn/"
        let iconSize = "@2x.png" // Boyutu ihtiyacınıza göre ayarlayabilirsiniz.
        let fullURL = baseURL + iconName + iconSize
        return URL(string: fullURL)
    }

  


    func checkLocationAuthorization() {
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            alert(title: "Location Permission Required", message: "Please allow the app to access your location.")
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            print("No location available")
            return
        }
        
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        // Hava durumu verilerini al
        fetchWeatherData(lat: lat, lon: lon)
        
        // Hava kalitesi verilerini al
        fetchAirQualityData(lat: lat, lon: lon)
        
        // Şehir adını al
        reverseGeocodeLocation(location: location)
    }
    
    func fetchAirQualityData(lat: Double, lon: Double) {
        Task {
            do {
                self.airQualityData = try await weatherManager.fetchAirQuality(lat: lat, lon: lon)
                
                // AQI verisini al
                DispatchQueue.main.async {
                    if let airQualityData = self.airQualityData {
                        if let aqi = airQualityData.list.first?.main.aqi {
                            print("AQI: \(aqi)")
                            // AQI'yi burada güncellemiyoruz
                        }
                    }
                    self.weatherTableView.reloadData()
                }
            } catch {
                print("Error fetching air quality data: \(error.localizedDescription)")
            }
        }
    }

    func fetchWeatherData(lat: Double, lon: Double) {
        Task {
            do {
                self.hourlyWeatherData = try await weatherManager.fetchWeather(lat: lat, lon: lon)
                
                // Hava durumu açıklamasını alın ve Türkçeye çevirin
                let weatherCondition = self.hourlyWeatherData.first?.weather.first?.description ?? "N/A"
                let translatedCondition: String
                
                switch weatherCondition.lowercased() {
                    case "clear sky":
                        translatedCondition = "Açık"
                    case "few clouds":
                        translatedCondition = "Az Bulutlu"
                    case "scattered clouds":
                        translatedCondition = "Dağınık Bulutlu"
                    case "broken clouds":
                        translatedCondition = "Parçalı Bulutlu"
                    case "shower rain":
                        translatedCondition = "Sağanak Yağışlı"
                    case "rain":
                        translatedCondition = "Yağmurlu"
                    case "thunderstorm":
                        translatedCondition = "Gök Gürültülü Fırtına"
                    case "snow":
                        translatedCondition = "Karlı"
                    case "mist":
                        translatedCondition = "Sisli"
                    case "light rain":
                        translatedCondition = "Hafif Yağmurlu"
                    case "overcast clouds":
                        translatedCondition = "Kapalı Bulutlu"
                    default:
                        translatedCondition = weatherCondition.capitalized
                }
                
                DispatchQueue.main.async {
                    self.degreeLabel.text = "\(Int(self.hourlyWeatherData.first?.main.temp ?? 0)) °"
                    self.airLabel.text = translatedCondition // Hava durumunu Türkçeye çevirilmiş olarak göster
                    self.updateUIForCurrentDay()
                    self.weatherCollectionView.reloadData()
                }
            } catch {
                print("Hava durumu verileri alınırken hata oluştu: \(error.localizedDescription)")
            }
        }
    }



    func reverseGeocodeLocation(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            if let error = error {
                print("Error in reverse geocoding: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first, let city = placemark.locality else {
                print("City not found")
                return
            }
            
            DispatchQueue.main.async {
                self?.cityLabel.text = city
            }
        }
    }

    // Geçerli enlem ve boylam kontrolü
    func isValidCoordinate(lat: Double, lon: Double) -> Bool {
        return (lat >= -90 && lat <= 90) && (lon >= -180 && lon <= 180)
    }

    func updateUIForCurrentDay() {
        // Update UI for current day
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }

    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alert.addAction(action)
        present(alert, animated: true)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}


extension Weather: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return segmentedControl.selectedSegmentIndex == 0 ? hourlyWeatherData.count : dailyWeatherData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WeatherCell", for: indexPath) as! WeatherCell
        
        if segmentedControl.selectedSegmentIndex == 0 {
            // Saatlik hava verisi
            guard indexPath.item < hourlyWeatherData.count else {
                return cell // Eğer dizinin boyutunu aşıyorsanız, boş bir hücre döndürün
            }
            
            let hourlyWeather = hourlyWeatherData[indexPath.item]
            cell.hourlyDegreeLabel.text = "\(Int(hourlyWeather.main.temp))°"
            cell.timeLabel.text = formatDate(unixTime: hourlyWeather.dt)
            
            let iconName = hourlyWeather.weather.first?.icon ?? defaultIcon
            if let iconURL = iconURL(iconName: iconName) {
                loadWeatherIcon(for: cell, from: iconURL)
            }
        } else {
            // Günlük hava verisi
            guard indexPath.item < dailyWeatherData.count else {
                return cell // Eğer dizinin boyutunu aşıyorsanız, boş bir hücre döndürün
            }
            
            let dailyWeather = dailyWeatherData[indexPath.item]
            cell.hourlyDegreeLabel.text = "\(Int(dailyWeather.temp.day))°"
            let date = Date(timeIntervalSince1970: TimeInterval(dailyWeather.dt))
            let dayFormatter = DateFormatter()
            dayFormatter.locale = Locale(identifier: "tr_TR")
            dayFormatter.dateFormat = "EEEE"
            cell.timeLabel.text = dayFormatter.string(from: date)
            
            let iconName = dailyWeather.weather.first?.icon ?? defaultIcon
            if let iconURL = iconURL(iconName: iconName) {
                loadWeatherIcon(for: cell, from: iconURL)
            }
        }

        configureCellAppearance(cell, at: indexPath)
        return cell
    }
    

    private func loadWeatherIcon(for cell: WeatherCell, from url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    cell.weatherImageView.image = image
                }
            } else {
                print("Hata: \(error?.localizedDescription ?? "Bilinmeyen hata")")
            }
        }.resume()
    }

    }

    private func configureCellAppearance(_ cell: WeatherCell, at indexPath: IndexPath) {
        cell.layer.borderColor = UIColor.gray.cgColor
        cell.layer.borderWidth = 0.5
        cell.layer.cornerRadius = 20.0
        cell.layer.masksToBounds = true
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 3)
        cell.layer.shadowOpacity = 0.3
        cell.layer.shadowRadius = 4.0
        cell.layer.masksToBounds = false
    }

    func formatDate(unixTime: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unixTime))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }


extension Weather: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = collectionView.bounds.width * 0.6
        let cellHeight = collectionView.bounds.height * 0.8
        return CGSize(width: cellWidth, height: cellHeight)
    }
}

extension Weather: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return airQualityProperties.count
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherDetailsCell", for: indexPath) as! WeatherDetailsCell
        
        guard let airQualityData = airQualityData, let airQuality = airQualityData.list.first else {
            cell.nameLabel.text = "Veri mevcut değil"
            cell.detailsLabel.text = ""
            cell.detailsImageView.image = nil
            return cell
        }
        
        cell.backgroundColor = UIColor(named: "Background")
        cell.cellBackgroundView.layer.cornerRadius = 10.0
        cell.selectionStyle = .none
        cell.cellBackgroundView.layer.borderWidth = 1.0
        
        let (propertyName, label) = airQualityProperties[indexPath.row]
        cell.nameLabel.text = "\(propertyName)"
        
        // Displaying custom images for air quality and wind speed
        switch indexPath.row {
        case 0: // Air Quality
            cell.detailsLabel.text = "\(label)\(airQuality.main.aqi)"
            cell.detailsImageView.image = UIImage(named: "havaKalitesi") // Local image for air quality
        case 1: // Wind Speed
            cell.detailsLabel.text = "\(label)\(10) m/s"
            cell.detailsImageView.image = UIImage(named: "ruzgarHizi") // Local image for wind speed
        case 2:
            cell.detailsLabel.text = "\(label)\(airQuality.components.co) µg/m³"
            loadIcon(for: "co", into: cell)
        case 3:
            cell.detailsLabel.text = "\(label)\(airQuality.components.no2) µg/m³"
            loadIcon(for: "no2", into: cell)
        case 4:
            cell.detailsLabel.text = "\(label)\(airQuality.components.o3) µg/m³"
            loadIcon(for: "o3", into: cell)
        case 5:
            cell.detailsLabel.text = "\(label)\(airQuality.components.pm10) µg/m³"
            loadIcon(for: "pm10", into: cell)
        case 6:
            cell.detailsLabel.text = "\(label)\(airQuality.components.pm2_5) µg/m³"
            loadIcon(for: "pm2_5", into: cell)
        case 7:
            cell.detailsLabel.text = "\(label)\(airQuality.components.so2) µg/m³"
            loadIcon(for: "so2", into: cell)
        default:
            cell.detailsLabel.text = "Veri mevcut değil"
            cell.detailsImageView.image = nil
        }
        
        return cell
    }
    
    // Helper function to load icon for other components
    private func loadIcon(for component: String, into cell: WeatherDetailsCell) {
        if let iconURL = getIconURL(for: component) {
            loadImage(from: iconURL) { image in
                DispatchQueue.main.async {
                    cell.detailsImageView.image = image
                }
            }
        } else {
            cell.detailsImageView.image = nil
        }
    }
    
    private func getIconURL(for component: String) -> URL? {
        let iconCode: String
        switch component {
        case "co", "so2", "no2":
            iconCode = "50d"
        case "pm10", "pm2_5":
            iconCode = "50d"
        case "o3":
            iconCode = "01d"
        case "wind":
            iconCode = "wind_icon_code" // Placeholder for a wind icon code
        case "aqi":
            iconCode = "aqi_icon_code" // Placeholder for an AQI icon code
        default:
            iconCode = "01d"
        }
        return URL(string: "https://openweathermap.org/img/wn/\(iconCode)@2x.png")
    }
    
    private func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }
}
