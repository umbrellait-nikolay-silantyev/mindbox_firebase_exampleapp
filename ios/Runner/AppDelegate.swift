import UIKit
import mindbox_ios
import Mindbox
import Firebase

@UIApplicationMain

@objc class AppDelegate: MindboxFlutterAppDelegate {
    
    private var channel: FlutterMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        channel = FlutterMethodChannel(name: "plugins.flutter.io/firebase_messaging",
                                       binaryMessenger: controller.binaryMessenger)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Передача токена APNS в SDK Mindbox и Firebase
    override func application( _ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Mindbox.shared.apnsTokenUpdate(deviceToken: deviceToken)
        Messaging.messaging().setAPNSToken(deviceToken, type: .unknown) }
    
    
    // Обработка пуша в активном состоянии
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
                // Не отрисовываем, если получили пуш от Firebase
                if userInfo.object(forKey: "gcm.message_id") != nil {
                    channel?.invokeMethod("Messaging#onMessage", arguments: mapRemoteMessageUserInfo(toMap: userInfo))
                }
                completionHandler([])
                
            }
        }
    
    
    // Функция обработки кликов по нотификации
    open override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {
            let request = response.notification.request
            let userInfo = request.content.userInfo as NSDictionary
            if userInfo.object(forKey: "gcm.message_id") != nil {
                // TODO: реализовать по аналогии с Firebase https://github.com/firebase/flutterfire/blob/master/packages/firebase_messaging/firebase_messaging/ios/Classes/FLTFirebaseMessagingPlugin.m
            }
            else {
                // передача данных с клика по пушу во Flutter
                SwiftMindboxIosPlugin.pushClicked(response: response)
                
                // передача факта клика по пушу
                Mindbox.shared.pushClicked(response: response)
                
                // передача факта открытия приложения по переходу на пуш
                Mindbox.shared.track(.push(response))
            }
            completionHandler()
        }
}

extension Bool {
    var intValue: Int {
        return self ? 1 : 0
    }
}

func mapRemoteMessageUserInfo(toMap userInfo: NSDictionary) -> NSDictionary {
    var message: [AnyHashable : Any] = [:]
    var data: [AnyHashable : Any] = [:]
    var notification: [AnyHashable : Any] = [:]
    var notificationIOS: [AnyHashable : Any] = [:]
    
    // message.data
    for key in userInfo.allKeys as! [String]  {
        
        // message.messageId
        if (key == "gcm.message_id") || (key == "google.message_id") || (key == "message_id") {
            message["messageId"] = userInfo[key]
        }
        
        // message.messageType
        if key == "message_type" {
            message["messageType"] = userInfo[key]
        }
        
        // message.collapseKey
        if key == "collapse_key" {
            message["collapseKey"] = userInfo[key]
        }
        
        // message.from
        if key == "from" {
            message["from"] = userInfo[key]
        }
        
        // message.sentTime
        if key == "google.c.a.ts" {
            message["sentTime"] = userInfo[key]
        }
        
        // message.to
        if (key == "to") || (key == "google.to") {
            message["to"] = userInfo[key]
        }
        
        // message.apple.imageUrl
        if key == "fcm_options" {
            if userInfo[key] != nil && (userInfo[key] as! NSDictionary)["image"] != nil {
                notificationIOS["imageUrl"] = (userInfo[key] as! NSDictionary)["image"]
            }
        }
        data[key] = userInfo[key]
    }
    message["data"] = data
    
    if userInfo["aps"] != nil {
        let apsDict = userInfo["aps"] as! NSDictionary
        
        // message.category
        if apsDict["category"] != nil {
            message["category"] = apsDict["category"]
        }
        
        // message.threadId
        if apsDict["thread-id"] != nil {
            message["threadId"] = apsDict["thread-id"]
        }
        
        // message.contentAvailable
        if apsDict["content-available"] != nil {
            message["contentAvailable"] = NSNumber(value: (apsDict["content-available"]) as! Int).boolValue
        }
        
        // message.mutableContent
        if apsDict["mutable-content"] != nil && (apsDict["mutable-content"] as! Bool).intValue == 1 {
            message["mutableContent"] = NSNumber(value: (apsDict["mutable-content"]) as! Int).boolValue
        }
        
        // message.notification.*
        if apsDict["alert"] != nil {
            
            // can be a string or dictionary
            if apsDict["alert"] is NSString {
                // message.notification.title
                notification["title"] = apsDict["alert"]
            } else if apsDict["alert"] is [AnyHashable : Any] {
                let apsAlertDict = apsDict["alert"] as! NSDictionary
                
                // message.notification.title
                if apsAlertDict["title"] != nil {
                    notification["title"] = apsAlertDict["title"]
                }
                
                // message.notification.titleLocKey
                if apsAlertDict["title-loc-key"] != nil {
                    notification["titleLocKey"] = apsAlertDict["title-loc-key"]
                }
                
                // message.notification.titleLocArgs
                if apsAlertDict["title-loc-args"] != nil {
                    notification["titleLocArgs"] = apsAlertDict["title-loc-args"]
                }
                
                // message.notification.body
                if apsAlertDict["body"] != nil {
                    notification["body"] = apsAlertDict["body"]
                }
                // message.notification.bodyLocKey
                if apsAlertDict["loc-key"] != nil {
                    notification["bodyLocKey"] = apsAlertDict["loc-key"]
                }
                
                // message.notification.bodyLocArgs
                if apsAlertDict["loc-args"] != nil {
                    notification["bodyLocArgs"] = apsAlertDict["loc-args"]
                }
                // message.notification.apple.subtitle
                if apsAlertDict["subtitle"] != nil {
                    notificationIOS["subtitle"] = apsAlertDict["subtitle"]
                }
                
                // Apple only
                // message.notification.apple.subtitleLocKey
                if apsAlertDict["subtitle-loc-key"] != nil {
                    notificationIOS["subtitleLocKey"] = apsAlertDict["subtitle-loc-key"]
                }
                // Apple only
                // message.notification.apple.subtitleLocArgs
                if apsAlertDict["subtitle-loc-args"] != nil {
                    notificationIOS["subtitleLocArgs"] = apsAlertDict["subtitle-loc-args"]
                }
                
                // Apple only
                // message.notification.apple.badge
                if apsAlertDict["badge"] != nil {
                    notificationIOS["badge"] = apsAlertDict["badge"]
                }
            }
            notification["apple"] = notificationIOS
            message["notification"] = notification
        }
        if apsDict["sound"] != nil {
            if apsDict["sound"] is NSString {
                // message.notification.apple.sound
                notification["sound"] = [
                    "name": apsDict["sound"],
                    "critical": NSNumber(value: false),
                    "volume": NSNumber(value: 1)
                ]
            } else if apsDict["sound"] is [AnyHashable : Any] {
                let apsSoundDict = apsDict["sound"] as! NSDictionary
                var notificationIOSSound: [AnyHashable : Any] = [:]
                
                // message.notification.apple.sound.name String
                if apsSoundDict["name"] != nil {
                    notificationIOSSound["name"] = apsSoundDict["name"]
                }
                
                // message.notification.apple.sound.critical Boolean
                if apsSoundDict["critical"] != nil {
                    notificationIOSSound["critical"] = NSNumber(value: (apsSoundDict["critical"]) as! Int).boolValue
                }
                
                // message.notification.apple.sound.volume Number
                if apsSoundDict["volume"] != nil {
                    notificationIOSSound["volume"] = apsSoundDict["volume"]
                }
                // message.notification.apple.sound
                notificationIOS["sound"] = notificationIOSSound
            }
            notification["apple"] = notificationIOS
            message["notification"] = notification
        }
    }
    return message as NSDictionary
}
