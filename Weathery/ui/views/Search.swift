import UIKit

class Search: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var cities: [String] = [] // Array to hold city names
    var filteredCities: [String] = [] // Filtered cities for search
    var favoriteCities: [String] = [] // Array to hold favorite city names
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        searchBar.barTintColor = UIColor(named: "Background")
        searchBar.searchTextField.backgroundColor = .white
        
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .white
        
        loadCities()
        loadFavorites()
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
                filteredCities = cities
                tableView.reloadData()
            } catch {
                print("Error loading cities: \(error)")
            }
        } else {
            print("City JSON file not found.")
        }
    }

    func loadFavorites() {
        if let savedFavorites = UserDefaults.standard.array(forKey: "FavoriteCities") as? [String] {
            favoriteCities = savedFavorites
        }
    }
    
    func saveFavorites() {
        UserDefaults.standard.set(favoriteCities, forKey: "FavoriteCities")
    }
}

extension Search: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredCities = searchText.isEmpty ? cities : cities.filter { $0.localizedCaseInsensitiveContains(searchText) }
        tableView.backgroundColor = filteredCities.isEmpty ? UIColor(named: "Background") : .clear
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension Search: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath)
        cell.textLabel?.text = filteredCities[indexPath.row]
        cell.textLabel?.textColor = .white
        cell.backgroundColor = UIColor(named: "Background")
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    // Swipe actions for each row
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let city = filteredCities[indexPath.row]
        
        let favoriteAction = UIContextualAction(style: .normal, title: "Favorite") { (action, view, completionHandler) in
            if !self.favoriteCities.contains(city) {
                self.favoriteCities.append(city)
                self.saveFavorites()
                print("Marked \(city) as favorite.")
            }
            completionHandler(true)
        }
        
        favoriteAction.backgroundColor = .systemRed
        
        return UISwipeActionsConfiguration(actions: [favoriteAction])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCity = filteredCities[indexPath.row]
        
        if let weatherVC = storyboard?.instantiateViewController(withIdentifier: "Weather") as? Weather {
            weatherVC.selectedCity = selectedCity
            navigationController?.pushViewController(weatherVC, animated: true)
        }
    }
}
