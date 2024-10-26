import UIKit

class Search: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var cities: [String] = [] // Array to hold city names
    var filteredCities: [String] = [] // Filtered cities for search
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        // Satır çizgilerini ayarlama
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .white // Çizgi rengini beyaz yap
        
        loadCities()
    }
    
    func loadCities() {
        if let path = Bundle.main.path(forResource: "cities", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let json = try JSONSerialization.jsonObject(with: data, options: []) as! [[String: String]]
                
                for city in json {
                    if let cityName = city["name"] {
                        cities.append(cityName)
                    }
                }
                filteredCities = cities // Initially show all cities
                tableView.reloadData()
            } catch {
                print("Error loading cities: \(error)")
            }
        } else {
            print("City JSON file not found.")
        }
    }
}

extension Search: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredCities = searchText.isEmpty ? cities : cities.filter { $0.localizedCaseInsensitiveContains(searchText) }
        
        if filteredCities.isEmpty {
            tableView.backgroundColor = UIColor(named: "Background")
        } else {
            tableView.backgroundColor = .clear // Use a transparent color if there are results
        }
        
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder() // Dismiss keyboard when search is tapped
    }
}


extension Search: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath)
        cell.textLabel?.text = filteredCities[indexPath.row]
        cell.textLabel?.textColor = .white // Yazı rengini beyaz yap
        cell.backgroundColor = UIColor(named: "Background") // Arka plan rengi
        cell.selectionStyle = .none 
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCity = filteredCities[indexPath.row]
        
        
        if let weatherVC = storyboard?.instantiateViewController(withIdentifier: "Weather") as? Weather {
            weatherVC.selectedCity = selectedCity
            print("Hava durumu sayfasına geçiliyor: \(selectedCity)")
            navigationController?.pushViewController(weatherVC, animated: true)
        } else {
            print("Weather view controller'ı yüklenemedi.")
        }
    }
}
