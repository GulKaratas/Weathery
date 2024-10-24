import UIKit
import CoreLocation

class Weather: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var weatherTableView: UITableView!
    @IBOutlet weak var weatherDetailsCollectionView: UICollectionView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var degreeLabel: UILabel!
    @IBOutlet weak var weatherCollectionView: UICollectionView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!

    var locationManager: CLLocationManager!
    var weatherManager = WeatherManager()
    var hourlyWeatherData: [HourlyWeather] = []
    var dailyWeatherData: [DailyWeather] = []
    
    var airQualityData: AirQuality?

    private let defaultIcon = "defaultIcon"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSegmentedControl()
        setupLocationManager()
        
        weatherCollectionView.delegate = self
        weatherCollectionView.dataSource = self
        
        weatherTableView.delegate = self
        weatherTableView.dataSource = self
        
        
        
        if let layout = weatherCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal // Horizontal scrolling
            layout.minimumLineSpacing = 10 // Spacing between cells
            layout.itemSize = CGSize(width: view.bounds.width * 0.8, height: view.bounds.height * 0.5) // Dynamic cell size
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
    
    @IBAction func segmentedControlChanged(_ sender: UISegmentedControl) {
        let lat = locationManager.location?.coordinate.latitude ?? 0
        let lon = locationManager.location?.coordinate.longitude ?? 0

        switch sender.selectedSegmentIndex {
        case 0:
            // Saatlik hava verisi
            Task {
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
            }
        case 1:
            // Günlük hava verisi (haftalık)
            Task {
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
            }
        default:
            break
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
    func fetchAirQualityData(lat: Double, lon: Double) {
        Task {
            do {
                self.airQualityData = try await weatherManager.fetchAirQuality(lat: lat, lon: lon)
                DispatchQueue.main.async {
                    self.weatherTableView.reloadData()
                }
            } catch {
                print("Error fetching air quality data: \(error.localizedDescription)")
            }
        }
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
        
        // Enlem ve boylam değerlerini kontrol et
        if isValidCoordinate(lat: lat, lon: lon) {
            Task {
                do {
                    self.hourlyWeatherData = try await weatherManager.fetchWeather(lat: lat, lon: lon)
                    DispatchQueue.main.async {
                        self.degreeLabel.text = "\(Int(self.hourlyWeatherData.first?.main.temp ?? 0)) °"
                        self.updateUIForCurrentDay()
                        self.weatherCollectionView.reloadData()
                    }
                } catch {
                    print("Error fetching weather data: \(error.localizedDescription)")
                }
            }
        } else {
            print("Geçersiz konum: lat: \(lat), lon: \(lon)")
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
        print("Air Quality Data Count: \(airQualityData?.list.count ?? 0)")
            return airQualityData?.list.count ?? 0    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherDetailsCell", for: indexPath) as! WeatherDetailsCell

        // Check if air quality data is available
        guard let airQualityEntry = airQualityData?.list[indexPath.row] else {
            cell.nameLabel.text = "Veri mevcut değil"
            cell.detailsLabel.text = ""
            cell.detailsImageView.image = nil
            return cell // Return empty cell if no data
        }

        // Set up the cell with the air quality data
        cell.nameLabel.text = "AQI Seviyesi: \(airQualityEntry.main.aqi)"
        cell.detailsLabel.text = "Hava Kalitesi İndeksi: \(airQualityEntry.main.aqi)"
        
        // Get the icon for the AQI level
        let iconName = getIconForAQI(aqi: airQualityEntry.main.aqi)
        cell.detailsImageView.image = UIImage(named: iconName)

        return cell
    }

    func validateCoordinates(lat: String, lon: String) -> (Double, Double)? {
        guard let latitude = Double(lat), let longitude = Double(lon) else {
            print("Geçersiz koordinat girişi")
            return nil
        }
        
        guard (latitude >= -90 && latitude <= 90) && (longitude >= -180 && longitude <= 180) else {
            print("Koordinatlar sınırların dışında")
            return nil
        }

        return (latitude, longitude)
    }
    // AQI seviyesine göre simge almak için yardımcı fonksiyon
    private func getIconForAQI(aqi: Int) -> String {
        switch aqi {
        case 1:
            return "good" // Replace with your actual icon names
        case 2:
            return "moderate"
        case 3:
            return "unhealthySensitive"
        case 4:
            return "unhealthy"
        case 5:
            return "veryUnhealthy"
        default:
            return "hazardous"
        }
    }
}
