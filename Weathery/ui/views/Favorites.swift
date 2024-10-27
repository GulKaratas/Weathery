import UIKit
import CoreLocation

class Favorites: UIViewController {
    
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var favoritesCollectionView: UICollectionView!
    var favoriteCities: [String] = []
    let weatherManager = WeatherManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        favoritesCollectionView.dataSource = self
        favoritesCollectionView.delegate = self
        
        configureCollectionViewLayout()
        loadFavorites()
        
        // Add observer to listen for updates
        NotificationCenter.default.addObserver(self, selector: #selector(refreshFavorites), name: .favoriteCityAdded, object: nil)
    }

    @objc func refreshFavorites() {
        loadFavorites() // Reloads the favorites from UserDefaults
        favoritesCollectionView.reloadData() // Updates the collection view
    }

    @IBAction func removeButton(_ sender: UIButton) {
        // Hangi şehir seçili olduğunu bul
        guard let cell = sender.superview?.superview as? FavoritesCell,
              let indexPath = favoritesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let cityToRemove = favoriteCities[indexPath.row]
        
        // Kullanıcıdan onay iste
        let alert = UIAlertController(title: "Onayla",
                                      message: "\(cityToRemove) şehrini favorilerden kaldırmak istediğinize emin misiniz?",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Hayır", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Evet", style: .destructive, handler: { _ in
            // Şehri favorilerden kaldır
            self.favoriteCities.remove(at: indexPath.row)
            self.saveFavorites()
            self.favoritesCollectionView.deleteItems(at: [indexPath]) // CollectionView'dan kaldır
        }))
        
        present(alert, animated: true, completion: nil)
    }
    func saveFavorites() {
        UserDefaults.standard.set(favoriteCities, forKey: "FavoriteCities")
    }
    
    func configureCollectionViewLayout() {
        let design = UICollectionViewFlowLayout()
        design.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        design.minimumInteritemSpacing = 10
        design.minimumLineSpacing = 10
        
        let screenWidth = UIScreen.main.bounds.width
        let itemWidth = (screenWidth - 30) / 2
        let itemHeight = itemWidth * 0.7
        design.itemSize = CGSize(width: itemWidth, height: itemHeight)
        
        favoritesCollectionView.collectionViewLayout = design
    }
    
    func loadFavorites() {
        if let savedFavorites = UserDefaults.standard.array(forKey: "FavoriteCities") as? [String] {
            favoriteCities = savedFavorites
            favoritesCollectionView.reloadData()
        }
    }
    
    func fetchCoordinates(for city: String, completion: @escaping (Double?, Double?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(city) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil,
                  let location = placemark.location else {
                print("Error fetching coordinates for city \(city): \(error?.localizedDescription ?? "Unknown error")")
                completion(nil, nil)
                return
            }
            completion(location.coordinate.latitude, location.coordinate.longitude)
        }
    }
}

extension Favorites: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return favoriteCities.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavoritesCell", for: indexPath) as! FavoritesCell
        let city = favoriteCities[indexPath.row]
        
        cell.configureAppearance()
        cell.cityFavoritesLabel.text = city
        
        fetchWeatherForCity(city) { weather in
            DispatchQueue.main.async {
                let temperature = Int(weather.main.temp)
                cell.degreeFavoritesLabel.text = "\(temperature)°"
                
                if let icon = weather.weather.first?.icon {
                    self.getImageForIcon(icon: icon) { image in
                        DispatchQueue.main.async {
                            cell.favoritesImageView.image = image
                        }
                    }
                }
            }
        }
        return cell
    }
    
    func fetchWeatherForCity(_ city: String, completion: @escaping (HourlyWeather) -> Void) {
        fetchCoordinates(for: city) { [weak self] lat, lon in
            guard let self = self, let lat = lat, let lon = lon else {
                print("No coordinates found for city: \(city)")
                return
            }
            
            Task {
                do {
                    let weatherData = try await self.weatherManager.fetchWeather(lat: lat, lon: lon)
                    if let firstWeather = weatherData.first {
                        completion(firstWeather)
                    }
                } catch {
                    print("Error fetching weather: \(error)")
                }
            }
        }
    }
    
    func getImageForIcon(icon: String, completion: @escaping (UIImage?) -> Void) {
        let urlString = "https://openweathermap.org/img/wn/\(icon)@2x.png"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error loading icon: \(error)")
                completion(nil)
                return
            }
            completion(data.flatMap(UIImage.init))
        }.resume()
    }
}

extension UICollectionViewCell {
    func configureAppearance() {
        self.layer.borderColor = UIColor.gray.cgColor
        self.layer.borderWidth = 0.5
        self.layer.cornerRadius = 10.0
    }
}
