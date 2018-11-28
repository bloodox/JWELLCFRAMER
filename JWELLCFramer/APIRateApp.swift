//
//  APIRateApp.swift
//  RateApp
//
//  Created by William Thompson on 1/28/18.
//  Copyright © 2018 William Thompson. All rights reserved.
//

import Foundation
import StoreKit

let appLaunches = "co.jwenterprises.carpentryplus25.applaunches"
let appLaunchesChanged = "co.jwenterprises.carpentryplus25.applaunches.changed"
let appInstallDate = "co.jwenterprises.carpentryplus25.install_date"
let appRatingShown = "co.jwenterprises.carpentryplus25.app_rating_shown"

public class APIRateApp: NSObject, UIAlertViewDelegate{
    var application: UIApplication!
    var userDefaults = UserDefaults()
    let requiredNumberOfLaunchesBeforeRating = 2
    
    public var appID: String!
    
    public static var sharedInstance = APIRateApp()
    
    //Mark: Initialization
    override public init() {
        super.init()
        setup()
    }
    
    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(appFinishedLaunching(notification:)), name: UIApplication.didFinishLaunchingNotification, object: nil)
    }
    
    //Mark: Notification Observers
    @objc func appFinishedLaunching(notification: NSNotification){
        if let _application = notification.object as? UIApplication {
            self.application = _application
            displayRatingsPromptIfRequired()
        }
        
        
    }
    
    //Mark: App launch count
    func getAppLaunchCount() -> Int {
        let launches = userDefaults.integer(forKey: appLaunches)
        return launches
    }
    
    func incrementAppLaunchCount() {
        var launches = userDefaults.integer(forKey: appLaunches)
        launches += 1
        userDefaults.set(launches, forKey: appLaunches)
        userDefaults.synchronize()
    }
    
    func resetAppLaunchCount() {
        userDefaults.set(0, forKey: appLaunches)
        userDefaults.synchronize()
    }
    
    func setFirstLaunchDate(){
        userDefaults.set(true, forKey: appInstallDate)
        userDefaults.synchronize()
    }
    
    func getFirstLaunchDate() -> NSDate {
        if let date = userDefaults.value(forKey: appInstallDate) as? NSDate {
            return date
        }
        return NSDate()
    }
    
    //Mark: App rating shown
    func setAppRatingShown(){
        userDefaults.set(true, forKey: appRatingShown)
        userDefaults.synchronize()
    }
    
    func hasShownAppRateing() -> Bool {
        let shown = userDefaults.bool(forKey: appRatingShown)
        return shown
    }
    
    // Mark: App Rating
    private func displayRatingsPromptIfRequired() {
        let appLaunchCount = getAppLaunchCount()
        if appLaunchCount >= self.requiredNumberOfLaunchesBeforeRating {
            if #available(iOS 10.3, *) {
                rateApp()
            }
            else {
                rateTheApp()
            }
            // Make changes here to support older versions than iOS 8 and uncomment the older version
        }
        incrementAppLaunchCount()
    }
    
    @available(iOS 10.3, *)
    private func rateApp() {
        SKStoreReviewController.requestReview()
        setAppRatingShown()
    }
    
    @available(iOS 8.0, *)
    private func rateTheApp() {
        // Must add localization keys in your localization files for supporting languages other than english
        let appName = Bundle(for: type(of: application.delegate!)).infoDictionary!["CFBundleName"] as? String
        let message = NSLocalizedString("Enjoying \(appName!) app? Please rate \(appName!)!", comment: "")
        let rateAlert = UIAlertController(title: NSLocalizedString("Rate \(appName!)", comment: ""), message: message, preferredStyle: .alert)
        let goToAppStore = UIAlertAction(title: NSLocalizedString("Rate", comment: ""), style: .default, handler: { (action) -> Void in
            let url = NSURL(string: "itms-apps://itunes.apple.com/app/id\(String(describing: self.appID))")
            UIApplication.shared.openURL(url! as URL)
            
            self.setAppRatingShown()
        })
        let cancelAction = UIAlertAction(title: NSLocalizedString("Not now", comment: ""), style: .cancel, handler: { (action) -> Void in
            self.resetAppLaunchCount()
        })
        
        rateAlert.addAction(goToAppStore)
        rateAlert.addAction(cancelAction)
        
        DispatchQueue.main.async(execute: { () -> Void in
            let window = self.application.windows[0]
            window.rootViewController?.present(rateAlert, animated: true, completion: nil)
            
        })
    }
}
