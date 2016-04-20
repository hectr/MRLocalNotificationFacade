// MRLocalNotificationFacade.h
//
// Copyright (c) 2015 Héctor Marqués
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Predefined domain for errors from `MRLocalNotificationFacade`.
 */
extern NSString *const MRLocalNotificationErrorDomain;


/**
 Error codes within the `MRLocalNotificationErrorDomain`.
 */
typedef enum {
    /** Unknown error (not currently used).   */
    MRLocalNotificationErrorUnknown               = 1950,
    /** Missing notification object.          */
    MRLocalNotificationErrorNilObject             = 1951,
    /** Notification object is not valid.     */
    MRLocalNotificationErrorInvalidObject         = 1952,
    /** No notification types allowed.        */
    MRLocalNotificationErrorNoneAllowed           = 1953,
    /** No notification sound type allowed.   */
    MRLocalNotificationErrorSoundNotAllowed       = 1954,
    /** No notification alert type allowed.   */
    MRLocalNotificationErrorAlertNotAllowed       = 1955,
    /** No notification badge type allowed.   */
    MRLocalNotificationErrorBadgeNotAllowed       = 1956,
    /** Notification fire date is not valid.  */
    MRLocalNotificationErrorInvalidDate           = 1957,
    /** Missing notification fire date.       */
    MRLocalNotificationErrorMissingDate           = 1958,
    /** Notification already scheduled.       */
    MRLocalNotificationErrorAlreadyScheduled      = 1959,
    /** Notification category not registered. */
    MRLocalNotificationErrorCategoryNotRegistered = 1960,
} MRLocalNotificationErrorCode;


/**
`MRLocalNotificationFacade` wraps most of the APIs related with local notifications.
 */
@interface MRLocalNotificationFacade : NSObject

/**
 Returns the singleton `MRLocalNotificationFacade` instance.
 
 @return The default instance of the receiver.
 */
+ (instancetype)defaultInstance;

/**
 Sound name used when one is needed for customizing a notification object.
 
 Default value is `UILocalNotificationDefaultSoundName`.
 */
@property (nullable, nonatomic, strong) NSString *defaultSoundName;

/**
 Creates an `UILocalNotification` and initializes it with the given parameters.

 @param fireDate The date and time when the system should deliver the notification.
 @param timeZone A boolean value indicating whether the notification should use the `defaultTimeZone` property value or not.
 @param category The name of a group of actions to display in the alert.
 @param userInfo A dictionary for passing custom information to the notified app. You may add arbitrary key-value pairs to this dictionary. However, the keys and values must be valid property-list types; if any are not, an exception is raised.
 @return An initialized `UILocalNotification`.
 */
- (UILocalNotification *)buildNotificationWithDate:(NSDate *)fireDate
                                          timeZone:(BOOL)timeZone
                                          category:(nullable NSString *)category
                                          userInfo:(nullable NSDictionary *)userInfo;

/**
 Creates an `UILocalNotification` and initializes it with the given parameters.
 
 @param fireInterval The time interval (since now) after which the system should deliver the notification.
 @param category The name of a group of actions to display in the alert.
 @param userInfo A dictionary for passing custom information to the notified app. You may add arbitrary key-value pairs to this dictionary. However, the keys and values must be valid property-list types; if any are not, an exception is raised.
 @return An initialized `UILocalNotification`.
 */
- (UILocalNotification *)buildNotificationWithInterval:(NSTimeInterval)fireInterval
                                              category:(nullable NSString *)category
                                              userInfo:(nullable NSDictionary *)userInfo;

/**
 Creates an `UILocalNotification` and initializes it with the given parameters.
 
 @param fireRegion The geographic region that triggers the notification.
 @param regionTriggersOnce A boolean value indicating whether crossing a geographic region boundary delivers only one notification.
 @param category The name of a group of actions to display in the alert.
 @param userInfo A dictionary for passing custom information to the notified app. You may add arbitrary key-value pairs to this dictionary. However, the keys and values must be valid property-list types; if any are not, an exception is raised.
 @return An initialized `UILocalNotification`.
 */
- (UILocalNotification *)buildNotificationWithRegion:(CLRegion *)fireRegion
                                        triggersOnce:(BOOL)regionTriggersOnce
                                            category:(nullable NSString *)category
                                            userInfo:(nullable NSDictionary *)userInfo;

/**
 Customizes the given `notification` with the given `calendarUnit` and the `defaultCalendar` property value.
 
 @param notification The notification object that will be customized.
 @param calendarUnit The calendar interval at which to reschedule the notification.
 */
- (void)customizeNotificationRepeat:(UILocalNotification *)notification
                           interval:(NSCalendarUnit)calendarUnit;

/**
 Customizes the given `notification` with the given parameters.
 
 @param notification The notification object that will be customized.
 @param alertTitle A short description of the reason for the alert.
 @param alertBody The message displayed in the notification alert.
 @param alertAction The title of the action button or slider.
 @param alertLaunchImage Identifies the image used as the launch image when the user taps (or slides) the action button (or slider).
 */
- (void)customizeNotificationAlert:(UILocalNotification *)notification
                             title:(nullable NSString *)alertTitle
                              body:(nullable NSString *)alertBody
                            action:(nullable NSString *)alertAction
                       launchImage:(nullable NSString *)alertLaunchImage;

/**
 Customizes the given `notification` with the given `badgeNumber` and a sound if `hasSound` is `YES`.
 
 @param notification The notification object that will be customized.
 @param badgeNumber The number to display as the app’s icon badge.
 @param hasSound A boolean that will determine whether to use or not the `defaultSoundName` property as the name of the file containing the sound to play when an alert is displayed.
 */
- (void)customizeNotification:(UILocalNotification *)notification
                 appIconBadge:(NSInteger)badgeNumber
                        sound:(BOOL)hasSound;

/**
 All currently scheduled local notifications.
 */
- (NSArray *)scheduledNotifications;

/**
 Cancels the delivery of the specified scheduled local notification.
 
 Calling this method also programmatically dismisses the notification if it is currently displaying an alert.
 
 @param notification The local notification to cancel. If it is `nil`, the method returns immediately.
 */
- (void)cancelNotification:(UILocalNotification *)notification;

/**
 Cancels the delivery of all scheduled local notifications.
 */
- (void)cancelAllNotifications;

@end


@interface MRLocalNotificationFacade (UIMutableUserNotificationCategory)

/**
 Creates an `UIMutableUserNotificationAction` and initializes it with the given parameters.
 
 @param identifier The string that you use internally to identify the action.
 @param title The localized string to use as the button title for the action.
 @param isDestructive A Boolean value indicating whether the action is destructive.
 @param runsInBackground Whether the app will run background or not when the action is performed.
 @param authRequired A Boolean value indicating whether the user must unlock the device before the action is performed.
 @return An initialized `UIMutableUserNotificationAction`.
 */
- (UIMutableUserNotificationAction *)buildAction:(NSString *)identifier
                                           title:(NSString *)title
                                     destructive:(BOOL)isDestructive
                                  backgroundMode:(BOOL)runsInBackground
                                  authentication:(BOOL)authRequired;
/**
 Creates an `UIMutableUserNotificationAction` and initializes it with the given parameters.
 
 @param identifier The name of the action group.
 @param minimalActions An array of `UIUserNotificationAction` objects representing the actions to display for `UIUserNotificationActionContextMinimal`.
 @param defaultActions  An array of `UIUserNotificationAction` objects representing the actions to display for `UIUserNotificationActionContextDefault`.
 @return An initialized `UIMutableUserNotificationCategory`.
 */
- (UIMutableUserNotificationCategory *)buildCategory:(NSString *)identifier
                                      minimalActions:(nullable NSArray *)minimalActions
                                      defaultActions:(nullable NSArray *)defaultActions;

/**
 Resets the given actions associated with the `UIUserNotificationActionContextMinimal` context.
 
 @param category `UIMutableUserNotificationCategory` object that will be customized.
 @param action0 First `UIUserNotificationAction` object (may be nil).
 @param action1 Second `UIUserNotificationAction` object (may be nil).
 */
- (void)customizeMinimalCategory:(UIMutableUserNotificationCategory *)category
                         action0:(nullable UIUserNotificationAction *)action0
                         action1:(nullable UIUserNotificationAction *)action1;

/**
 Resets the given actions associated with the `UIUserNotificationActionContextDefault` context.
 
 @param category `UIMutableUserNotificationCategory` object that will be customized.
 @param action0 First `UIUserNotificationAction` object (may be nil).
 @param action1 Second `UIUserNotificationAction` object (may be nil).
 @param action2 Third `UIUserNotificationAction` object (may be nil).
 @param action3 Forth `UIUserNotificationAction` object (may be nil).
 */
- (void)customizeDefaultCategory:(UIMutableUserNotificationCategory *)category
                         action0:(nullable UIUserNotificationAction *)action0
                         action1:(nullable UIUserNotificationAction *)action1
                         action2:(nullable UIUserNotificationAction *)action2
                         action3:(nullable UIUserNotificationAction *)action3;

/**
 Stores the given `handler` block associated with the given `identifier`.
 
 @param handler The block that should be invoked for handling an action for a notification `userInfo`.
 @param identifier The identifier of the action that should be associated with the handler.
 */
- (void)setNotificationHandler:(void(^_Nullable)(NSString *identifier, UILocalNotification *notification))handler
       forActionWithIdentifier:(NSString *)identifier;

@end


@interface MRLocalNotificationFacade (UIUserNotificationSettings)

/**
 Registers your preferred options for notifying the user.
 
 @param badgeType The app badges its icon.
 @param alertType The app posts an alert.
 @param soundType The app plays a sound.
 @param categories A set of `UIUserNotificationCategory` objects that define the groups of actions a notification may include.
 */
- (void)registerForNotificationWithBadges:(BOOL)badgeType
                                   alerts:(BOOL)alertType
                                   sounds:(BOOL)soundType
                               categories:(nullable NSSet *)categories;

/**
 Returns the user notification settings for the app.
 
 @return A user notification settings object indicating the types of notifications that your app may use.
 */
- (nullable UIUserNotificationSettings *)currentUserNotificationSettings;

/**
 Returns the category from the given user notification settings object whose identifier matches the given one.
 
 @param categoryIdentifier The category identifier.
 @param notificationSettings The user notification settings object.
 @return The category object contained in `notificationSettings` whose identifier matches `categoryIdentifier`.
 */
- (nullable UIUserNotificationCategory *)getCategoryForIdentifier:(nullable NSString *)categoryIdentifier
                                     fromUserNotificationSettings:(nullable UIUserNotificationSettings *)notificationSettings;


/**
 Returns a Boolean indicating whether the app is currently registered for any of the types of local notifications.
 
 @return `YES` if the app is registered for any of the types of local notifications or `NO` if registration has not occurred or all types have been denied by the user.
 */
- (BOOL)isRegisteredForNotifications;

/**
 Returns whether the app is allowed to badge app's icon or not.
 
 @return `YES` if the app can badge app's icon; `NO` otherwise.
 */
- (BOOL)isBadgeTypeAllowed;

/**
 Returns whether the app is allowed to play a sound or not.
 
 @return `YES` if the app can play a sound; `NO` otherwise.
 */
- (BOOL)isSoundTypeAllowed;

/**
 Returns whether the app is allowed to post an alert or not.
 
 @return `YES` if the app can post an alert; `NO` otherwise.
 */
- (BOOL)isAlertTypeAllowed;

@end


@interface MRLocalNotificationFacade (UIAlertController)

/**
 View controller used as presenting view controller by the method `showAlertController:`.
 
 If `defaultAlertPresenter` is `nil`, a new view controller instance is created for every `showAlertController:` invocation.
 */
@property (nullable, nonatomic, strong) UIViewController *defaultAlertPresenter;

/**
 Block invoked when the user cancels an alert created with the `buildAlertControlForNotification:` method.
 */
@property (nullable, nonatomic, copy) void(^onDidCancelNotificationAlert)(UILocalNotification *notification);

/**
 Creates an alert for displaying the given notification.
 
 This method makes no use notification's `alertAction`, but uses its `category` as option buttons.
 
 @param notification `UILocalNotification` used for customizing alert message and buttons.
 @return An initialized alert controller object.
 */
- (UIAlertController *)buildAlertControlForNotification:(UILocalNotification *)notification;

/**
 Presents the given alert controller.
 
 @param alert Alert controller object that needs to be presented.
 */
- (void)showAlertController:(UIAlertController *)alert;

@end


@interface MRLocalNotificationFacade (UIApplication)

/**
 Returns the `UIApplication` instance.
 
 Default value is `UIApplication.sharedApplication`.
 */
@property (nullable, nonatomic, strong) UIApplication *defaultApplication;

/**
 Block invoked by `application:didReceiveLocalNotification:` method when a notification is passed as parameter.
 
 `shouldShowAlert` is given a default value according to the application state, but can be changed within the block.
 */
@property (nullable, nonatomic, copy) void(^onDidReceiveNotification)(UILocalNotification *notification, BOOL *shouldShowAlert);

/**
 Returns `YES` if the method `application:didRegisterUserNotificationSettings:` is known to have been received with a not `nil` notification settings parameter.
 
 The return value is taken from the user defaults.
 */
@property (nonatomic, readonly) BOOL hasRegisteredNotifications;

/**
 Returns the local notification object (if any) from the given launch options dictionary.
 @param launchOptions Launch options dictionary.
 @returns The local notification object or `nil` if `UIApplicationLaunchOptionsLocalNotificationKey` does not contain a local notification or the given `launchOptions` was `nil`.
 */
- (nullable UILocalNotification *)getNotificationFromLaunchOptions:(nullable NSDictionary *)launchOptions;

/**
 The number currently set as the badge of the app icon in Springboard.
 */
- (NSInteger)applicationIconBadgeNumber;

/**
 Sets the number for the badge of the app icon in Springboard.
 
 @param applicationIconBadgeNumber New value for the badge of the app icon.
 */
- (void)setApplicationIconBadgeNumber:(NSInteger)applicationIconBadgeNumber;

/**
 Handles `application:didRegisterUserNotificationSettings:`.
 
 This method stores the value returned by `hasRegisteredNotifications`.
 
 @param notificationSettings The user notification settings that are available to your app. The settings in this object may be different than the ones you originally requested. If it is `nil`, the method returns immediately.
 */
- (void)handleDidRegisterUserNotificationSettings:(nullable UIUserNotificationSettings *)notificationSettings;

/**
 Handles `application:didReceiveLocalNotification:`.
 
 This method invokes `onDidReceiveNotification` block and may display the given notification using an alert controller when the application is in active state (`UIApplicationStateActive`).
 
 @param notification A local notification that encapsulates details about the notification, potentially including custom data. If it is `nil`, the method returns immediately.
 */
- (void)handleDidReceiveLocalNotification:(nullable UILocalNotification *)notification;

/**
 Handles `application:handleActionWithIdentifier:forLocalNotification:completionHandler:`.
 
 This method invokes the action hanlder block associated with the given action `identifier`.
 
 @param identifier The identifier associated with the custom action. This string corresponds to the identifier from the `UILocalNotificationAction` object that was used to configure the action in the local notification.
 @param notification The local notification object that was triggered.
 @param completionHandler A block to call when you are finished performing the action.
 */
- (void)handleActionWithIdentifier:(nullable NSString *)identifier
              forLocalNotification:(nullable UILocalNotification *)notification
                 completionHandler:(void (^_Nullable)())completionHandler;

@end


@interface MRLocalNotificationFacade (NSDate)

/**
 Time zone used when one is needed for building a notification object.
 */
@property (nullable, nonatomic, strong) NSTimeZone *defaultTimeZone;

/**
 Calendar used when one is needed for building `NSDate` objects or customizing notification's *repeat interval*.
 
 Default value is `NSCalendar.autoupdatingCurrentCalendar`.
 */
@property (nullable, nonatomic, strong) NSCalendar *defaultCalendar;

/**
 Returns a new `NSDate` object representing the absolute time calculated from given components and `defaultCalendar` property.
 
 The parameters are interpreted in the context of the calendar with which it is used (`defaultCalendar`).
 
 @param day The number of day units for the receiver.
 @param month The number of month units for the receiver.
 @param year The number of year units for the receiver.
 @param hour The number of hour units for the receiver.
 @param minute The number of minute units for the receiver.
 @param second The number of second units for the receiver.
 @return A new `NSDate` object representing the absolute time calculated from `defaultCalendar` property and `day`, `month`, `year`, `hour`, `minute` and `second`.
 */
- (NSDate *)buildDateWithDay:(NSInteger)day
                       month:(NSInteger)month
                        year:(NSInteger)year
                        hour:(NSInteger)hour
                      minute:(NSInteger)minute
                      second:(NSInteger)second;

/**
 Converts the given date from GMT to the `defaultTimeZone`.
 
 @param gmtDate `NSDate` object in GMT.
 @return `NSDate` object converted from the receiver's default time zone equivalent to the given GMT date.
 */
- (NSDate *)convertDateToDefaultTimeZone:(NSDate *)gmtDate;

/**
 Converts the given `date` from `defaultTimeZone` to GMT.
 
 @param timeDate `NSDate` object in the receiver's default time zone.
 @return `NSDate` object converted from GMT equivalent to the given time zone date.
 */
- (NSDate *)convertDateToGMT:(NSDate *)timeDate;

/**
 Retrieves the components of the given `date` using the receiver's `defaultCalendar`.
 
 @param date The date.
 @param day A pointer for storing the day value.
 @param month A pointer for storing the month value.
 @param year A pointer for storing the year value.
 @param hour A pointer for storing the hour value.
 @param minute A pointer for storing the minute value.
 @param second A pointer for storing the second value.
 */
- (void)date:(NSDate *)date
      getDay:(nullable NSInteger *)day
       month:(nullable NSInteger *)month
        year:(nullable NSInteger *)year
        hour:(nullable NSInteger *)hour
      minute:(nullable NSInteger *)minute
      second:(nullable NSInteger *)second;

/**
 Returns the `fireDate` of the given `notification` converted to GMT (if needed).
 
 @param notification The notification object.
 @return The fire date converted from the notification's `timeZone` to GMT or `nil` if the given `notification` hasn't got `fireDate` or it is `nil` itself.
 */
- (NSDate *)getGMTFireDateFromNotification:(UILocalNotification *)notification;

@end


@interface MRLocalNotificationFacade (NSErrorRecoveryAttempting)

/**
 URL used for handling a 'Contact Support' action.
 
 This property is used when building the error objects used by the `scheduleNotification:withError:` method.
 */
@property (nullable, nonatomic, strong) NSURL *contactSuportURL;

/**
 Block invoked when the user cancels an alert created with the `buildAlertControlForError:` method.
 */
@property (nullable, nonatomic, copy) void(^onDidCancelErrorAlert)(NSError *error);

/**
 Sets a URL in the `contactSupportURL` property using the `mailto` scheme and the given email address.
 
 @param emailAddress The support email address.
 */
- (void)setContactSuportURLWithEmailAddress:(nullable NSString *)emailAddress;

/**
 Returns whether the `scheduledNotifications` array contains an object thas is equal (`isEqual:`) to the given `notification` or not.
 
 @param notification The object used for checking equality with each element of the array.
 @return `YES` if there is an object equal; `NO` otherwise.
 */
- (BOOL)scheduledNotificationsContainsNotification:(UILocalNotification *)notification;

/**
 Schedules a local notification for delivery at its encapsulated date and time.
 
 Prior to scheduling any local notifications, you must call the registerUserNotificationSettings: method to let the system know what types of alerts, if any, you plan to display to the user.
 
 @param notification The local notification object that you want to schedule.
 @param errorPtr If the notification cannot be scheduled or if it has been scheduled but some problem has been detected, upon return contains an instance of `NSError` that describes the problem.
 @return `YES` if the notification has been scheduled; `NO` otherwise.
 */
- (BOOL)scheduleNotification:(nullable UILocalNotification *)notification
                   withError:(NSError *_Nullable*_Nullable)errorPtr;

/**
 Creates an alert for displaying the given error.
 
 @param error `NSError` used for customizing alert message and buttons.
 @return An initialized alert controller object.
 */
- (UIAlertController *)buildAlertControlForError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
