
# MRLocalNotificationFacade

`MRLocalNotificationFacade` wraps most of the APIs required for dealing with local notifications in *iOS*:

- **Registration of user notification settings** without direct manipulation of `UIUserNotificationSettings` objects.

```objc
- (void)registerForNotificationWithBadges:(BOOL)badgeType alerts:(BOOL)alertType sounds:(BOOL)soundType categories:(NSSet *)categories;
- (BOOL)isBadgeTypeAllowed;
- (BOOL)isSoundTypeAllowed;
- (BOOL)isAlertTypeAllowed;
// etc.
```

- **Error aware notification scheduling**.

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

- **Creation and customization of notifications, categories and actions**.

```objc
- (UILocalNotification *)buildNotificationWithDate:(NSDate *)fireDate timeZone:(BOOL)timeZone category:(NSString *)category userInfo:(NSDictionary *)userInfo;
- (UILocalNotification *)buildNotificationWithRegion:(CLRegion *)fireRegion triggersOnce:(BOOL)regionTriggersOnce category:(NSString *)category userInfo:(NSDictionary *)userInfo;
- (UIMutableUserNotificationAction *)buildAction:(NSString *)identifier title:(NSString *)title destructive:(BOOL)isDestructive backgroundMode:(BOOL)runsInBackground authentication:(BOOL)authRequired;
- (UIMutableUserNotificationCategory *)buildCategory:(NSString *)identifier minimalActions:(NSArray *)minimalActions defaultActions:(NSArray *)defaultActions;
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

License
-------

**MRLocalNotificationFacade** is available under the MIT license. See the *LICENSE* file for more info.
