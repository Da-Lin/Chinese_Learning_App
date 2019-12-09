import UIKit
import WebKit

class TutorialViewController: UIViewController, WKNavigationDelegate {
    @IBOutlet weak var webView: WKWebView!
    
    public var link = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let webViewConfiguration = webView.configuration
        webViewConfiguration.allowsInlineMediaPlayback = true
        //webView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))
        let url = URL(string: link)!
        webView.load(URLRequest(url: url))
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let value =  UIInterfaceOrientation.landscapeLeft.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeLeft
    }

}
