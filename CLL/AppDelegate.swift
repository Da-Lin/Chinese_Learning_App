import UIKit
import IQKeyboardManagerSwift
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        IQKeyboardManager.shared.enable = true
        //checkIfAppEnabled()
        
        FirebaseApp.configure()
        //checkLoggedIn()
        return true
    }
    
    func checkLoggedIn(){
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        if Auth.auth().currentUser != nil{
            let uid = Auth.auth().currentUser!.uid
            let db = Firestore.firestore()
            db.collection("users").document(uid).getDocument { (document, err) in
                if let document = document, document.exists {
                    let data = document.data()!
                    let role = data["role"] as! Int
                    if role == Constants.UserRole.teacher {
                       let teacherHomeViewController = storyBoard.instantiateViewController(identifier: Constants.Storyboard.studentHomeViewController) as! StudentHomeViewController
                        
                        let navigationVC = self.window!.rootViewController as! UINavigationController
                        
                        navigationVC.pushViewController(teacherHomeViewController, animated: false)
                    }else{
                        let studentHomeViewController = storyBoard.instantiateViewController(identifier: Constants.Storyboard.studentHomeViewController) as! StudentHomeViewController
                        
                        let navigationVC = self.window!.rootViewController as! UINavigationController
                        
                        navigationVC.pushViewController(studentHomeViewController, animated: false)
                    }
                    
                } else {
                    print("Document does not exist")
                }
            }

        }
    }
    
    
//    private func checkIfAppEnabled() {
//        let url = URL(string: "https://web.lukereichold.com/natural-chinese/config.json")!
//        let request = URLRequest(url: url)
//        print(request)
//        URLSession.shared.dataTask(with: request as URLRequest) {data, response, error in
//            if error != nil {
//                print(error!.localizedDescription)
//            }
//            guard let data = data else { return }
//            do {
//                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Bool]
//
//                if !json["app_enabled"]! {
//                    fatalError("app is not enabled!")
//                }
//
//            } catch let jsonError {
//                print(jsonError)
//            }
//        }.resume()
//    }
}

