//
//  AppDelegate.swift
//  iOS_Graph_Plug
//
//  Created by macbook pro on 09/01/19.
//  Copyright © 2019 Omni-Bridge. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if UserDefaults.standard.value(forKey: "StartURLFromServer") == nil{
            self.callToSetConfigeUrl()
        }else{
            self.loadInitialViewController()
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK:- Confige URL
    
    /// Uset to set confige url from server
    private func callToSetConfigeUrl(){
        if General.isConnectedToNetwork(){
            if GetApiConfig.execute(){
                self.loadInitialViewController()
            }else{
                showErrorAlert(message: Error_Message.SERVERSIDE_FAILURE_MESSAGE)
            }
        }else{
            self.showErrorAlert(message: Error_Message.NETWORK_FAILURE_MESSAGE)
        }
    }
    
    /// Used to load initial view controller
    private func loadInitialViewController(){
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let initialViewController : UINavigationController = mainStoryboard.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = initialViewController
    }
    
    
    /// Used to show Error alert
    ///
    /// - Parameter message: message
    func showErrorAlert(message : String){
        let alertVC = UIAlertController(title: Error_Message.SERVERSIDE_FAILURE_TITLE , message: message, preferredStyle: UIAlertController.Style.alert)
        let okAction = UIAlertAction(title: "Okay", style: UIAlertAction.Style.cancel) { (alert) in
            exit(0)
        }
        alertVC.addAction(okAction)
        DispatchQueue.main.async {
            let alertWindow = UIWindow(frame: UIScreen.main.bounds)
            alertWindow.rootViewController = UIViewController()
            alertWindow.windowLevel = UIWindow.Level.alert + 1;
            alertWindow.makeKeyAndVisible()
            alertWindow.rootViewController?.present(alertVC, animated: true, completion: nil)
        }
    }
    
}

