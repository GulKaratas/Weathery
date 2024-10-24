import UIKit
import CoreLocation

class Weather: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var degreeLabel: UILabel!
    @IBOutlet weak var weatherCollectionView: UICollectionView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!

    var locationManager: CLLocationManager!
    var weatherManager = WeatherManager()
    var hourlyWeatherData: [HourlyWeather] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSegmentedControl()
        setupLocationManager()

        weatherCollectionView.delegate = self
        weatherCollectionView.dataSource = self
        
        if let layout = weatherCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.scrollDirection = .horizontal // Yatay kaydırma
                layout.minimumLineSpacing = 10 // Hücreler arasındaki boşluk
                layout.itemSize = CGSize(width: view.bounds.width * 0.8, height: view.bounds.height * 0.5) // Hücre boyutunu dinamik olarak ayarlayın
            }
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Yatay kaydırma için layout ayarları
        if let layout = weatherCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal // Yatay kaydırma
            layout.minimumLineSpacing = 10 // Hücreler arasındaki boşluk
            layout.itemSize = CGSize(width: weatherCollectionView.frame.width * 0.8, height: weatherCollectionView.frame.height * 0.5)
        }
    }

    @IBAction func segmentedControlChanged(_ sender: Any) {
        switch (sender as AnyObject).selectedSegmentIndex {
            case 0:
                // Saatlik veriler
                weatherCollectionView.reloadData()
            case 1:
                // Haftalık veriler (eklenmeli)
                weatherCollectionView.reloadData()
            default:
                break
            }
    }
    func setupSegmentedControl() {
        segmentedControl.backgroundColor = UIColor.clear
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
    

    func checkLocationAuthorization() {
        let status = CLLocationManager.authorizationStatus()

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            alert(title: "Konum İzni Gerekli", message: "Lütfen uygulamanın konumunuza erişmesine izin verin.")
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude

            Task {
                do {
                    self.hourlyWeatherData = try await weatherManager.fetchWeather(lat: lat, lon: lon)
                    DispatchQueue.main.async {
                        self.updateUIForCurrentDay()
                        self.weatherCollectionView.reloadData()
                    }
                } catch {
                    print("Hava durumu verileri alınamadı: \(error.localizedDescription)")
                }
            }

            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first, let city = placemark.locality {
                    DispatchQueue.main.async {
                        self.cityLabel.text = city
                    }
                } else {
                    print("Şehir bilgisi alınamadı")
                }
            }
        }
    }

    func updateUIForCurrentDay() {
        // Güncelleme işlemi için gerekli
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Konum alınamadı: \(error.localizedDescription)")
    }

    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Tamam", style: .default)
        alert.addAction(action)
        present(alert, animated: true)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}
func iconURL(iconName: String) -> URL? {
        return URL(string: "https://openweathermap.org/img/wn/\(iconName)@2x.png")
    }



// CollectionView için veri kaynağı
extension Weather: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hourlyWeatherData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WeatherCell", for: indexPath) as! WeatherCell

        let weather = hourlyWeatherData[indexPath.item]
        
        // Sıcaklık
        cell.hourlyDegreeLabel.text = "\(Int(weather.main.temp))°"
        
        // Saat
        cell.timeLabel.text = formatDate(unixTime: weather.dt)
        cell.weatherImageView.image = nil // Eski resmi temizleyin

        // Hava durumu ikonu (URL'den)
        if let iconURL = iconURL(iconName: weather.weather.first?.icon ?? "defaultIcon") {
            // URL'den ikonu çekmek için URLSession veya bir resim yükleyici kullanmalısınız (örn. Kingfisher ya da SDWebImage)
            // Basit bir örnek için:
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: iconURL) {
                    DispatchQueue.main.async {
                        cell.weatherImageView.image = UIImage(data: data)
                    }
                }
            }
        }
        
        cell.layer.borderColor = UIColor.gray.cgColor
            cell.layer.borderWidth = 0.5
            cell.layer.cornerRadius = 20.0 // Daha büyük bir radius ile kenarları daha yuvarlak hale getiriyoruz.
            cell.layer.masksToBounds = true // Hücrenin içeriklerinin kenarlardan taşmaması için bunu true yapıyoruz.

            // Gölge efektleri
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 3)
            cell.layer.shadowOpacity = 0.3
            cell.layer.shadowRadius = 4.0
            cell.layer.masksToBounds = false // Gölgenin kenarlardan taşmasına izin veriyoruz.

            // Seçilen hücreyi renklendirme
            if indexPath == collectionView.indexPathsForSelectedItems?.first {
                cell.backgroundColor = UIColor(named: "SelectedColor") // Seçili hücre rengi
            } else {
                cell.backgroundColor = UIColor.white // Varsayılan hücre rengi
            }

        return cell
    }



    func formatDate(unixTime: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unixTime))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }
}
extension Weather: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Hücre boyutunu daha uzun ve ince yapıyoruz
        let cellWidth = collectionView.bounds.width * 0.6 // Genişliği %60 oranında yapıyoruz (daha ince)
        let cellHeight = collectionView.bounds.height * 0.8 // Yüksekliği %80 oranında yapıyoruz (daha uzun)
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
}
