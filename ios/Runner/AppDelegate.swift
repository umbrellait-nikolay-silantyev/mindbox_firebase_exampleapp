
import UIKit
import Flutter
import Mindbox
import MindboxNotifications
import mindbox_ios
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        registerForRemoteNotifications()
        
        // Регистрация фоновых задач для iOS выше 13
        if #available(iOS 13.0, *) {
            Mindbox.shared.registerBGTasks()
        } else {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        }
        
        // Передача факта открытия приложения
        Mindbox.shared.track(.launch(launchOptions))
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    //    MARK: didRegisterForRemoteNotificationsWithDeviceToken
    // Передача токена APNS в SDK Mindbox и Firebase
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            Mindbox.shared.apnsTokenUpdate(deviceToken: deviceToken)
            Messaging.messaging().setAPNSToken(deviceToken, type: .unknown)
            
        }
    
    // Регистрация фоновых задач для iOS до 13
    override func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
            Mindbox.shared.application(application, performFetchWithCompletionHandler: completionHandler)
        }
    
    //    MARK: registerForRemoteNotifications
    //    Функция запроса разрешения на уведомления. В комплишн блоке надо передать статус разрешения в SDK Mindbox
    func registerForRemoteNotifications() {
        UNUserNotificationCenter.current().delegate = self
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                print("Permission granted: \(granted)")
                if let error = error {
                    print("NotificationsRequestAuthorization failed with error: \(error.localizedDescription)")
                }
                Mindbox.shared.notificationsRequestAuthorization(granted: granted)
            }
        }
    }
    
    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        // Передача ссылки, если приложение открыто через universalLink
        Mindbox.shared.track(.universalLink(userActivity))
        return true
    }
    
    
    // Отрисовка пуша в активном приложении
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            let userInfo = notification.request.content.userInfo as NSDictionary
            // Проверка что пуш от Mindbox
            if userInfo.object(forKey: "uniqueKey") != nil {
                // Отрисовываем
                completionHandler([.alert, .badge, .sound])
            } else {
                // Не отрисовываем, передаем стандартному обработчику
                super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
            }
        }
    
    //    MARK: didReceive response
    //    Функция обработки кликов по нотификации
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {
            let request = response.notification.request
            let userInfo = request.content.userInfo as NSDictionary
            if userInfo.object(forKey: "gcm.message_id") != nil {
                // Если пуш от Firebase, то вызываем стандартный обработчик
                super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
            }
            else {
                // передача данных с клика по пушу во Flutter
                SwiftMindboxIosPlugin.pushClicked(response: response)
                
                // передача факта клика по пушу
                Mindbox.shared.pushClicked(response: response)
                
                // передача факта открытия приложения по переходу на пуш
                Mindbox.shared.track(.push(response))
                completionHandler()
            }
            
        }
}
