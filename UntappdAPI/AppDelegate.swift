//
//  AppDelegate.swift
//  UntappdAPI
//
//  Created by Jeff Kempista on 12/8/14.
//  Copyright (c) 2014 Jeff Kempista. All rights reserved.
//

import UIKit
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        JLRoutes.addRoute("x-callback-url/authenticate/*", handler: {
            [unowned self] (parameters) -> Bool in
            if let accessToken = parameters["access_token"] as? String {
                self.setupUntappdApi(newAccessToken: accessToken)
            }
            return true
        })
        
        setupUntappdApi()
        setupMocktails()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        setupMocktails()
        
        if (NSUserDefaults.standardUserDefaults().boolForKey("clear_keychain")) {
            clearKeychain()
            setupUntappdApi(newAccessToken: nil)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            window?.rootViewController = storyboard.instantiateInitialViewController() as? UIViewController
            window?.makeKeyAndVisible()
            
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "clear_keychain")
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        return JLRoutes.routeURL(url)
    }
    
    func clearKeychain() {
        SSKeychain.deletePasswordForService("UntappdAPI", account: "AccessToken")
    }
    
    func setupMocktails() {
        
        if (NSUserDefaults.standardUserDefaults().boolForKey("mocktail_enabled")) {
            clearKeychain()
            
            let mocktailsURL = NSBundle.mainBundle().resourceURL
            Mocktail.startWithContentsOfDirectoryAtURL(mocktailsURL, configuration: Alamofire.Manager.sharedInstance.session.configuration)
            
            Untappd.Router.accessToken = "MOCKTAILS"
        }
    }
    
    func setupUntappdApi(newAccessToken: String? = nil) {
        var accessTokenToSet = newAccessToken
        
        if (accessTokenToSet == nil) {
            if let accessToken = SSKeychain.passwordForService("UntappdAPI", account: "AccessToken") {
                if (accessToken.utf16Count > 0) {
                    accessTokenToSet = accessToken
                } else {
                    accessTokenToSet = nil
                }
            }
        } else {
            SSKeychain.setPassword(accessTokenToSet, forService: "UntappdAPI", account: "AccessToken")
        }
        Untappd.Router.accessToken = accessTokenToSet
    }

}

