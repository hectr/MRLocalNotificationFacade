
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let notificationFacade = MRLocalNotificationFacade.defaultInstance()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let notification = notificationFacade.getNotificationFromLaunchOptions(launchOptions)
        notificationFacade.handleDidReceiveLocalNotification(notification)
        return true
    }

    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        NSNotificationCenter.defaultCenter().postNotificationName("reloadData", object: self)
        notificationFacade.handleDidReceiveLocalNotification(notification)
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        notificationFacade.handleActionWithIdentifier(identifier, forLocalNotification: notification, completionHandler: completionHandler)
    }
}

