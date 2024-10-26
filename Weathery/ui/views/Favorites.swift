import UIKit

class Favorites: UIViewController {
    
    @IBOutlet weak var favoritesCollectionView: UICollectionView!
    
    var favoriteCities: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        favoritesCollectionView.dataSource = self
        favoritesCollectionView.delegate = self
        
      
        configureCollectionViewLayout()
        loadFavorites()
    }
    func configureCollectionViewLayout() {
        let design = UICollectionViewFlowLayout()
           
           // Kenar boşlukları
           design.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
           design.minimumInteritemSpacing = 10 // Yan yana hücreler arası boşluk
           design.minimumLineSpacing = 10 // Alt alta hücreler arası boşluk
           
           // Hücre genişliği ve yükseklik oranı
           let screenWidth = UIScreen.main.bounds.width
           let itemWidth = (screenWidth - 30) / 2 // İki sütun için genişlik
        let itemHeight = itemWidth * 0.7 // Dikdörtgen görünüm için yükseklik oranı (burada oranı 1.4 kullandık)

           design.itemSize = CGSize(width: itemWidth, height: itemHeight)
           
           favoritesCollectionView.collectionViewLayout = design
    }
    func loadFavorites() {
        if let savedFavorites = UserDefaults.standard.array(forKey: "FavoriteCities") as? [String] {
            favoriteCities = savedFavorites
            favoritesCollectionView.reloadData()
        }
    }
    
    func getCoordinatesForCity(_ city: String) -> (lat: Double, lon: Double)? {
        let coordinates = [
            "Afyonkarahisar": (lat: 38.7500, lon: 30.5567),
            "Adıyaman": (lat: 37.7642, lon: 38.2765),
            "Aksaray": (lat: 38.3623, lon: 34.0207)
            // Add more cities here...
        ]
        
        return coordinates[city]
    }
}

extension Favorites: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return favoriteCities.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavoritesCell", for: indexPath) as! FavoritesCell
        let city = favoriteCities[indexPath.row]
        
        // Set up cell appearance
        cell.layer.borderColor = UIColor.gray.cgColor
        cell.layer.borderWidth = 0.5
        cell.layer.cornerRadius = 10.0
        
        cell.cityFavoritesLabel.text = city
        fetchWeatherForCity(city) { weather in
            let temperature = weather.main.temp
            cell.degreeFavoritesLabel.text = "\(Int(temperature))°"
            
            if let icon = weather.weather.first?.icon {
                // Asenkron olarak ikonu yükle
                self.getImageForIcon(icon: icon) { image in
                    DispatchQueue.main.async {
                        cell.favoritesImageView.image = image
                    }
                }
            }
        }
        
        return cell
    }
    
    func fetchWeatherForCity(_ city: String, completion: @escaping (HourlyWeather) -> Void) {
        guard let coordinates = getCoordinatesForCity(city) else {
            print("No coordinates found for city: \(city)")
            return
        }
        
        Task {
            do {
                let weatherManager = WeatherManager()
                let hourlyWeather = try await weatherManager.fetchWeather(lat: coordinates.lat, lon: coordinates.lon)
                
                if let firstWeather = hourlyWeather.first {
                    completion(firstWeather)
                }
            } catch {
                print("Error fetching weather: \(error)")
            }
        }
    }
    
    func getImageForIcon(icon: String, completion: @escaping (UIImage?) -> Void) {
        let iconSize = "@2x.png" // Gerekirse boyutu ayarlayın
        let baseURL = "https://openweathermap.org/img/wn/"
        let urlString = "\(baseURL)\(icon)\(iconSize)"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        // URLSession kullanarak asenkron yükleme
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Hata: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            
            completion(image)
        }.resume()
    }
}
