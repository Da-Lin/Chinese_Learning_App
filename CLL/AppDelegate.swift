import UIKit
import IQKeyboardManagerSwift
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        IQKeyboardManager.shared.enable = true
        checkIfAppEnabled()
        
        FirebaseApp.configure()
        return true
    }
    
    private func checkIfAppEnabled() {
        let url = URL(string: "https://web.lukereichold.com/natural-chinese/config.json")!
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request as URLRequest) {data, response, error in
            if error != nil {
                print(error!.localizedDescription)
            }
            guard let data = data else { return }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Bool]
                
                if !json["app_enabled"]! {
                    fatalError("app is not enabled!")
                }
                
            } catch let jsonError {
                print(jsonError)
            }
        }.resume()
    }
}

