import UIKit

class CustomTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // TabBar görünüm ayarlarını yap
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = UIColor(named: "Background")
        
        // Item'ların renklerini ayarla
        colorChange(itemAppearance: appearance.stackedLayoutAppearance)
        colorChange(itemAppearance: appearance.inlineLayoutAppearance)
        colorChange(itemAppearance: appearance.compactInlineLayoutAppearance)

        // TabBar'ın görünümünü uygulamak için güncelle
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }

    func colorChange(itemAppearance: UITabBarItemAppearance) {
        itemAppearance.selected.iconColor = UIColor(named: "SelectColor")
        itemAppearance.normal.iconColor = UIColor(named: "TextColor")
    }
}
