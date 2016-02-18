[![Version](https://img.shields.io/cocoapods/v/MRLocalNotificationFacade.svg?style=flat)](http://cocoapods.org/pods/MRLocalNotificationFacade)
[![License](https://img.shields.io/cocoapods/l/MRLocalNotificationFacade.svg?style=flat)](http://cocoapods.org/pods/MRLocalNotificationFacade)
[![Platform](https://img.shields.io/cocoapods/p/MRLocalNotificationFacade.svg?style=flat)](http://cocoapods.org/pods/MRLocalNotificationFacade)

Overview
========

`MRLocalNotificationFacade` is a class that wraps most of the APIs required for dealing with local notifications in *iOS*:

- **Registration of user notification settings** without direct manipulation of `UIUserNotificationSettings` objects.

```objc
- (void)registerForNotificationWithBadges:(BOOL)badgeType alerts:(BOOL)alertType sounds:(BOOL)soundType categories:(NSSet *)categories;
- (BOOL)isBadgeTypeAllowed;
- (BOOL)isSoundTypeAllowed;
- (BOOL)isAlertTypeAllowed;
// etc.
```

- **Error aware notification scheduling** with `NSError` object that you can inspect or display to the user.

```objc
- (BOOL)scheduleNotification:(UILocalNotification *)notification withError:(NSError **)errorPtr;
- (UIAlertController *)buildAlertControlForError:(NSError *)error;

```

- **App delegate methods handling**.

```objc
// application:didRegisterUserNotificationSettings:
- (void)handleDidRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings;
// application:didReceiveLocalNotification:
- (void)handleDidReceiveLocalNotification:(UILocalNotification *)notification;
// application:handleActionWithIdentifier:forLocalNotification:completionHandler: 
- (void)handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler;
// etc.
```

- **Display of local notifications** when the application is in `UIApplicationStateActive` state.

```objc
- (UIAlertController *)buildAlertControlForNotification:(UILocalNotification *)notification;
- (void)showAlertController:(UIAlertController *)alert;
```

- **Creation and manipulation of date objects**.

```objc
- (NSDate *)buildDateWithDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year hour:(NSInteger)hour minute:(NSInteger)minute second:(NSInteger)second;
- (NSDate *)getGMTFireDateFromNotification:(UILocalNotification *)notification;
// etc.
```

- **Creation and customization of notifications, categories and actions**.

```objc
- (UILocalNotification *)buildNotificationWithDate:(NSDate *)fireDate timeZone:(BOOL)timeZone category:(NSString *)category userInfo:(NSDictionary *)userInfo;
- (UILocalNotification *)buildNotificationWithRegion:(CLRegion *)fireRegion triggersOnce:(BOOL)regionTriggersOnce category:(NSString *)category userInfo:(NSDictionary *)userInfo;
- (UIMutableUserNotificationAction *)buildAction:(NSString *)identifier title:(NSString *)title destructive:(BOOL)isDestructive backgroundMode:(BOOL)runsInBackground authentication:(BOOL)authRequired;
- (UIMutableUserNotificationCategory *)buildCategory:(NSString *)identifier minimalActions:(NSArray *)minimalActions defaultActions:(NSArray *)defaultActions;
// etc.
```

![Notification example](notification.jpg?raw=true "Notification example")

Getting started
===============

Installation
------------

### CocoaPods

To add **MRLocalNotificationFacade** to your app, add `pod "MRLocalNotificationFacade"` to your *Podfile*.

### Manually

Copy the *MRLocalNotificationFacade* directory into your project.

Usage
-----

You do pretty much the same you would do if you were not using *MRLocalNotificationFacade*, but using it.

### Register for notifications

First you invoke **MRLocalNotificationFacade** handlers from the app delegate methods:

```objc
@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    MRLocalNotificationFacade *notificationFacade = MRLocalNotificationFacade.defaultInstance;
    [notificationFacade setContactSuportURLWithEmailAddress:@"support@example.com"];
    UILocalNotification *notification = [notificationFacade getNotificationFromLaunchOptions:options];
    [notificationFacade handleDidReceiveLocalNotification:notification];
    return YES;
}
- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notification {
    MRLocalNotificationFacade *notificationFacade = MRLocalNotificationFacade.defaultInstance;
    [notificationFacade handleDidReceiveLocalNotification:notification];
}
- (void)application:(UIApplication *)app didRegisterUserNotificationSettings:(UIUserNotificationSettings *)settings {
    MRLocalNotificationFacade *notificationFacade = MRLocalNotificationFacade.defaultInstance;
    [notificationFacade handleDidRegisterUserNotificationSettings:settings];
}
- (void)application:(UIApplication *)app handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())handler {
    MRLocalNotificationFacade *notificationFacade = MRLocalNotificationFacade.defaultInstance;
    [notificationFacade handleActionWithIdentifier:identifier forLocalNotification:notification completionHandler:handler];
}
@end
```

Then you just register your preferred options for notifying the user at your best convenience:

```objc
- (IBAction)registerForNotificationsAction:(id)sender {
    MRLocalNotificationFacade *notificationFacade = MRLocalNotificationFacade.defaultInstance;
    NSSet *categories = ...; // use notificationFacade for creating your action groups
    [notificationFacade registerForNotificationWithBadges:YES alerts:YES sounds:YES categories:categories];
}
```

### Schedule notification

You just proceed to create the notification and schedule it using the several `build*` and `customize*` methods available in `MRLocalNotificationFacade`:

```objc
- (void)scheduleNotification:(NSString *)text date:(NSDate *)date category:(NSString *)category {
    MRLocalNotificationFacade *notificationFacade = MRLocalNotificationFacade.defaultInstance;
    UILocalNotification *notification = [notificationFacade buildNotificationWithDate:date
                                                                             timeZone:NO
                                                                             category:category
                                                                             userInfo:nil];
    [notificationFacade customizeNotificationAlert:notification
                                             title:nil
                                              body:text
                                            action:nil
                                       launchImage:nil];
    NSError *error;
    BOOL scheduled = [notificationFacade scheduleNotification:notification
                                                      withError:&error];
    if (error && scheduled) {
        // user needs to change settings, the recovery attempter will handle this
        UIAlertController *alert = [notificationFacade buildAlertControlForError:error];
        [notificationFacade showAlertController:alert];
    } else {
        // this is bad, maybe you prefer to do something else...
        UIAlertController *alert = [notificationFacade buildAlertControlForError:error];
        [notificationFacade showAlertController:alert];
    }
}
```

License
=======

**MRLocalNotificationFacade** is available under the MIT license. See the *LICENSE* file for more info.
