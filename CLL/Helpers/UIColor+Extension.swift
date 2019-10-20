import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    static let backgroundGrey = UIColor(white: 230/255.0, alpha: 1)

    static let primaryRed = UIColor(red: 203, green: 45, blue: 32) // #cb2d20
    static let lightRedWhite = UIColor(red: 255, green: 129, blue: 119)

    static let salmon = UIColor(red: 237 / 255.0, green: 103 / 255.0, blue: 98 / 255.0, alpha: 1)
    
//    struct NavBar {
//        static let buttonNormal = UIColor.black
//        static let buttonHighlighted = UIColor.primaryBlue
//    }
//
//    struct FloatingButton {
//        static let buttonNormal = UIColor.primaryBlue
//    }
}

