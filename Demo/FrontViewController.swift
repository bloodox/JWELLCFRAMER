//
//  FrontViewController.swift
//  Demo
//
//  Created by William Thompson on 11/24/18.
//  Copyright © 2018 J.W.Enterprises LLC. All rights reserved.
//

import UIKit
import JWELLCFramer

class FrontViewController: UIViewController {

    @IBOutlet weak var intLabel: UILabel!
    var intLabelHasValue = false
    let intLabelHasValueKey = "intLabelKey"
    var intLabelValue = 0
    let intLabelValueKey = "intLabelValueKey"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !KeyChainAccess.standard.bool(forKey: intLabelHasValueKey)! {
            intLabel.text = "0"
        }
        else {
            intLabelValue = KeyChainAccess.standard.integer(forKey: intLabelValueKey)!
            intLabel.text = "\(intLabelValue)"
        }
        
    }
    
    @IBAction func incrementIntLabel(_ sender: Any) {
        KeyChainAccess.standard.set(true, forKey: intLabelHasValueKey)
        if !intLabelHasValue {
            intLabelHasValue = KeyChainAccess.standard.bool(forKey: intLabelHasValueKey)!
        }
        intLabelValue += 1
        KeyChainAccess.standard.set(intLabelValue, forKey: intLabelValueKey)
        intLabel.text = "\(intLabelValue)"
        
    }
    
    @IBAction func removeKeyChainValues(_ sender: Any) {
        KeyChainAccess.wipeKeychain()
        intLabelValue = KeyChainAccess.standard.integer(forKey: intLabelValueKey)!
        intLabel.text = "\(intLabelValue)"
    
    }
    
    
    @IBAction func toggleMenu(_ sender: Any) {
        self.revealViewController()?.leftRevealToggle(sender: self)
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
