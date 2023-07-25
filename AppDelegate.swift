//
//  AppDelegate.swift
//  Karmon Pay
//
//  Created by Iskandar Parpiev on 18/06/22.
//

import UIKit
import XCoordinator
import IQKeyboardManagerSwift
import FirebaseCore
import FirebaseMessaging
import UserNotifications


@main
@available(iOS 13.0.0, *)
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let window: UIWindow! = UIWindow()
    let router = AppCoordinator().strongRouter
    var timer = Timer()
    var runCount = 0
    var backgroundTime: Date?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        Messaging.messaging().isAutoInitEnabled = true
        registerForPushNotifications()
        
//        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
//            self?.addBlurEffect()
//        }
//        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
//            self?.removeBlurEffect()
//        }
        if #available(iOS 13.0, *) {
            window.overrideUserInterfaceStyle = .light
            UIView.appearance().overrideUserInterfaceStyle = .light
            NotificationCenter.default.addObserver(self, selector: #selector(traitCollectionDidChange(_:)), name: UIApplication.didChangeStatusBarFrameNotification, object: nil)
        }
        
        LanguageManager.setupCurrentLanguage()
        
        if let hideData = UserDefaults.getHideData() {
            IS_HIDE_ALL = hideData
        }
        
        
        if let _ = UserDefaults.getPinCode() {
            UserDefaults.removePinCode()
        }
        
        if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            appearance.shadowImage = createTopBorderImage(color: AppColors.borderColor, height: 1)
            appearance.shadowColor = .clear
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            } else {
                // Fallback on earlier versions
            }
        } else {
            // Fallback on earlier versions
        }
        
        func createTopBorderImage(color: UIColor, height: CGFloat) -> UIImage? {
            let size = CGSize(width: UIScreen.main.bounds.width, height: height)
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            color.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: height))
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        }
        
        IQKeyboardManager.shared.enable = true
        setupTabBarAppearance()
        
        router.setRoot(for: window)
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 58, target: self, selector: #selector(self.fireTimer), userInfo: nil, repeats: true)
        }
        
        return true
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
//        AppDelegateViewModel().registerDeviceToken(token: deviceTokenString)
        debugPrint("tocken:",deviceTokenString)
      
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // 1. Print out error if PNs registration not successful
        print("Failed to register for remote notifications with error: \(error)")
    }
    
    func addBlurEffect() {
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = window?.bounds ?? UIScreen.main.bounds
        window?.addSubview(blurView)
    }
    
    func removeBlurEffect() {
        window?.subviews.first(where: { $0 is UIVisualEffectView })?.removeFromSuperview()
    }
    @objc func traitCollectionDidChange(_ notification: Notification) {
        setupTabBarAppearance()
    }
    func applicationWillResignActive(_ application: UIApplication) {
        //        let blurEffect = UIBlurEffect(style: .regular)
        //        let blurView = UIVisualEffectView(effect: blurEffect)
        //        blurView.frame = window?.bounds ?? UIScreen.main.bounds
        //         blurView.tag = 221122
        //        window?.addSubview(blurView)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        backgroundTime = Date()
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        NotificationCenter.default.post(name:Notification.Name(HIDE_SHOW), object: nil)
        
        
        
        if let autoLock = UserDefaults.getAutoLock() {
            
            
            if let backgroundTime = backgroundTime, Date().timeIntervalSince(backgroundTime) >= autoLock * 60 {
                SHOW_PIN_CODE = true
                SHOW_PIN_CODE_WITHOUT_TIME = true
//                NotificationCenter.default.post(name: Notification.Name(REFRESH_EVERYTHING_FROM_BACK_PIN), object: nil)
                NotificationCenter.default.post(name:Notification.Name("fromBackground"), object: nil)

            } else {
                
      
            }
            backgroundTime = nil
            
            
        } else {
            if let backgroundTime = backgroundTime, Date().timeIntervalSince(backgroundTime) >= 5 * 60 {
                SHOW_PIN_CODE = true
                SHOW_PIN_CODE_WITHOUT_TIME = true
                NotificationCenter.default.post(name:Notification.Name("fromBackground"), object: nil)
                NotificationCenter.default.post(name: Notification.Name(REFRESH_EVERYTHING_FROM_BACK), object: nil)
            }
            backgroundTime = nil
        }
        
        
    }
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask(rawValue: UIInterfaceOrientationMask.portrait.rawValue)
    }
    
    
    
    func applicationWillEnterForeground(_ application: UIApplication) {
//        UserDefaults.setIsExpiredSessionToken(true)
//        self.window?.viewWithTag(221122)?.removeFromSuperview()
        //        window?.subviews.first(where: { $0 is UIVisualEffectView })?.removeFromSuperview()
    }
    
    private func setupTabBarAppearance() {
        if #available(iOS 13.0, *) {
            let isDarkMode = window.traitCollection.userInterfaceStyle == .dark
            UITabBar.appearance().barTintColor = UIColor(named: isDarkMode ? "tabBarColorDark" : "tabBarColorLight")
            UITabBar.appearance().backgroundColor = .white
            UITabBar.appearance().tintColor = AppColors.themeGreen
        } else {
            UITabBar.appearance().barTintColor = UIColor(named: "tabBarColorLight")
            UITabBar.appearance().backgroundColor = .white
            UITabBar.appearance().tintColor = AppColors.themeGreen
        }
    }
    
    
    @objc func fireTimer() {
        debugPrint("Timer fired! \(Date())" )
        
        runCount += 1
        
        UserDefaults.setIsExpiredSessionToken(true)
        
        if runCount == 60 {
            print("Timer reset!")
            timer.invalidate()
        }
    }
    
}

@available(iOS 13.0.0, *)
extension AppDelegate: MessagingDelegate, UNUserNotificationCenterDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("Token: \(token)")
            AppDelegateViewModel().registerDeviceToken(token: token)
        }
        
    }
    
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            print("Permission granted: \(granted)")
            // 1. Check if permission granted
            guard granted else { return }
            // 2. Attempt registration for remote notifications on the main thread
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    
    // Receive displayed notifications for iOS 10 devices.,,,
    @available(iOS 13.0.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
    -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        
//        parseNotification(userInfo: userInfo)
        Messaging.messaging().appDidReceiveMessage(userInfo)
        print(userInfo)
        
        // Change this to your preferred presentation option
        return [[.alert, .sound]]
    }
    
    func parseNotification(userInfo: [AnyHashable: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userInfo, options: [])
            let decoder = JSONDecoder()
            let welcome = try decoder.decode(Welcome.self, from: jsonData)
            
            // Access the parsed data
            print("Title (English):", welcome.meta.title.en)
            print("Body (Russian):", welcome.meta.body.ru)
            print("Image URL:", welcome.meta.image)
            print("Notification ID:", welcome.meta.nid)
            print("Notification Type:", welcome.meta.ntype)
            
            print("Example Key 1:", welcome.data.exampleKey1)
            print("Example Nested Key:", welcome.data.exampleKey2.exampleNestedKey)
        } catch {
            print("Error parsing JSON:", error)
        }
    }
    
    @available(iOS 13.0.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        
        parseNotification(userInfo: userInfo)
        
        print(userInfo)
    }
    
    
    @available(iOS 13.0.0, *)
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        parseNotification(userInfo: userInfo)
        completionHandler(.noData)
    }
    
    
}


