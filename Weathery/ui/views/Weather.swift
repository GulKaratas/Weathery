import UIKit
import CoreLocation

class Weather: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var airLabel: UILabel!
    @IBOutlet weak var degreeLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    
    
    var locationManager: CLLocationManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // locationManager'ı doğru şekilde başlatıyoruz
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Konum izni isteme
        checkLocationAuthorization()
    }

    // Konum izni durumu kontrol ediliyor
    func checkLocationAuthorization() {
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .notDetermined:
            // İzin verilmediyse konum izni istiyoruz
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            // İzin verildiyse konum almaya başlıyoruz
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            // İzin reddedildiyse kullanıcıya bilgi veriyoruz
            alert(title: "Konum İzni Gerekli", message: "Lütfen uygulamanın konumunuza erişmesine izin verin.")
        default:
            break
        }
    }

    // Konum başarıyla alındığında çalışır
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first, let city = placemark.locality {
                    DispatchQueue.main.async {
                        self.cityLabel.text = city  // Şehir ismini cityLabel'a yazdırıyoruz
                    }
                } else {
                    print("Şehir bilgisi alınamadı")
                }
            }
        }
    }

    // Konum alınamadığında çalışır
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let nsError = error as NSError
        print("Konum alınamadı: \(nsError.localizedDescription)")

        if nsError.code == CLError.denied.rawValue {
            alert(title: "Hata", message: "Konum izni reddedildi.")
        } else {
            alert(title: "Hata", message: "Konum alınamıyor: \(nsError.localizedDescription)")
        }
    }

    // Kullanıcıya uyarı gösterme fonksiyonu
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

    // Konum izni durumunu takip etmek için
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}
