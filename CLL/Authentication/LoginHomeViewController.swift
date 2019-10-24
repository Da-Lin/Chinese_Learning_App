//
//  LoginHomeViewController.swift
//  CLL
//
//  Created by Da Lin on 10/24/19.
//  Copyright © 2019 Luke Reichold. All rights reserved.
//

import UIKit

class LoginHomeViewController: UIViewController {

    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpElement()
        // Do any additional setup after loading the view.
    }
    
    func setUpElement(){
        Utilities.styleFilledButton(signUpButton)
        Utilities.styleHollowButton(loginButton)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
