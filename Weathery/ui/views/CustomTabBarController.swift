import UIKit

class CustomTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

       
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = UIColor(named: "Background")
        
        
        colorChange(itemAppearance: appearance.stackedLayoutAppearance)
        colorChange(itemAppearance: appearance.inlineLayoutAppearance)
        colorChange(itemAppearance: appearance.compactInlineLayoutAppearance)

        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }

    func colorChange(itemAppearance: UITabBarItemAppearance) {
        itemAppearance.selected.iconColor = UIColor(named: "SelectColor")
        itemAppearance.normal.iconColor = UIColor(named: "TextColor")
    }
}
