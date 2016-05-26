// MRLocalNotificationFacade.m
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

#import "MRLocalNotificationFacade.h"


NSString *const MRLocalNotificationErrorDomain = @"MRLocalNotificationErrorDomain";

NSString *const MRRecoveryURLErrorKey = @"MRRecoveryURLErrorKey";

static NSString *const kMRUserNotificationsRegisteredKey = @"kMRUserNotificationsRegisteredKey";


#pragma mark - MRLocalNotificationFacadeAlertViewController_ -


// `UIViewController` subclass with custom rotation handling.
@interface MRLocalNotificationFacadeAlertViewController_ : UIViewController
@end


@implementation MRLocalNotificationFacadeAlertViewController_

#pragma mark Private

- (CGFloat)mr_degreesToRadians:(CGFloat const)degrees
{
    return degrees*M_PI/180;
}

- (CGAffineTransform)mr_transformForOrientation:(UIInterfaceOrientation const)orientation
{
    switch (orientation) {
            
        case UIInterfaceOrientationLandscapeLeft:
            return CGAffineTransformMakeRotation(-[self mr_degreesToRadians:90]);
            
        case UIInterfaceOrientationLandscapeRight:
            return CGAffineTransformMakeRotation([self mr_degreesToRadians:90]);
            
        case UIInterfaceOrientationPortraitUpsideDown:
            return CGAffineTransformMakeRotation([self mr_degreesToRadians:180]);
            
        case UIInterfaceOrientationPortrait:
        default:
            return CGAffineTransformMakeRotation([self mr_degreesToRadians:0]);
    }
}

#pragma mark NSNotification

- (void)statusBarDidChangeFrame:(NSNotification *const)notification
{
    UIApplication *const application = UIApplication.sharedApplication;
    UIInterfaceOrientation const orientation = [application statusBarOrientation];
    UIWindow *const window = self.view.window;
    window.transform = [self mr_transformForOrientation:orientation];
    dispatch_async(dispatch_get_main_queue(), ^{
        window.bounds = application.keyWindow.bounds;
    });
}

- (void)viewDidAppear:(BOOL const)animated
{
    [super viewDidAppear:animated];
    UIApplication *const application = UIApplication.sharedApplication;
    UIInterfaceOrientation const orientation = [application statusBarOrientation];
    CGAffineTransform const transform = [self mr_transformForOrientation:orientation];
    UIWindow *const window = self.view.window;
    window.transform = transform;
    CGRect const frame = window.frame;
    window.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
}

#pragma mark - UIViewController

- (BOOL)shouldAutorotate
{
    return NO;
}

#pragma mark - NSObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSNotificationCenter *const defaultCenter = NSNotificationCenter.defaultCenter;
        [defaultCenter addObserver:self
                          selector:@selector(statusBarDidChangeFrame:)
                              name:UIApplicationDidChangeStatusBarFrameNotification
                            object:nil];
    }
    return self;
}

- (void)dealloc
{
    NSNotificationCenter *const defaultCenter = NSNotificationCenter.defaultCenter;
    [defaultCenter removeObserver:self];
}

@end


#pragma mark - MRLocalNotificationFacade -


@interface MRLocalNotificationFacade ()
@property (nonatomic, strong) UIApplication *defaultApplication;
@property (nonatomic, copy) void(^onDidReceiveNotification)(UILocalNotification *n, BOOL *alert);
@property (nonatomic, readwrite) BOOL hasRegisteredNotifications;
@property (nonatomic, strong) NSTimeZone *defaultTimeZone;
@property (nonatomic, strong) NSCalendar *defaultCalendar;
@property (nonatomic, strong) UIViewController *defaultAlertPresenter;
@property (nonatomic, copy) void(^onDidCancelNotificationAlert)(UILocalNotification *notification);
@property (nonatomic, strong) NSMutableDictionary *actionHandlers;
@property (nonatomic, strong) NSURL *contactSupportURL;
@property (nonatomic, copy) void(^onDidCancelErrorAlert)(NSError *error);
@end


@implementation MRLocalNotificationFacade

+ (instancetype)defaultInstance
{
    static MRLocalNotificationFacade *__defaultInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __defaultInstance = [[self alloc] init];
    });
    return __defaultInstance;
}

- (UIMutableUserNotificationAction *)buildAction:(NSString *const)identifier
                                           title:(NSString *const)title
                                     destructive:(BOOL const)isDestructive
                                  backgroundMode:(BOOL const)runsInBackground
                                  authentication:(BOOL const)authRequired
{
    NSParameterAssert(identifier);
    NSParameterAssert(title);
    NSParameterAssert(runsInBackground || authRequired);
    UIMutableUserNotificationAction *const action =
    [[UIMutableUserNotificationAction alloc] init];
    if (runsInBackground) {
        action.activationMode = UIUserNotificationActivationModeBackground;
    } else {
        action.activationMode = UIUserNotificationActivationModeForeground;
    }
    action.title = title;
    action.identifier = identifier;
    action.destructive = isDestructive;
    action.authenticationRequired = authRequired;
    return action;
}

- (UIMutableUserNotificationCategory *)buildCategory:(NSString *const)identifier
                                      minimalActions:(NSArray *const)minimalActions
                                      defaultActions:(NSArray *const)defaultActions
{
    NSParameterAssert(identifier);
    NSParameterAssert(minimalActions.count <= 2);
    NSParameterAssert(defaultActions.count <= 4);
    UIMutableUserNotificationCategory *const category =
    [[UIMutableUserNotificationCategory alloc] init];
    category.identifier = identifier;
    [category setActions:minimalActions forContext:UIUserNotificationActionContextMinimal];
    [category setActions:defaultActions forContext:UIUserNotificationActionContextDefault];
    return category;
}

- (void)customizeMinimalCategory:(UIMutableUserNotificationCategory *const)category
                         action0:(UIUserNotificationAction *const)action0
                         action1:(UIUserNotificationAction *const)action1
{
    NSParameterAssert(category);
    NSMutableArray *const actions = [NSMutableArray arrayWithCapacity:4];
    if (action0) {
        [actions addObject:action0];
    }
    if (action1) {
        [actions addObject:action1];
    }
    [category setActions:actions forContext:UIUserNotificationActionContextMinimal];
}

- (void)customizeDefaultCategory:(UIMutableUserNotificationCategory *const)category
                         action0:(UIUserNotificationAction *const)action0
                         action1:(UIUserNotificationAction *const)action1
                         action2:(UIUserNotificationAction *const)action2
                         action3:(UIUserNotificationAction *const)action3
{
    NSParameterAssert(category);
    NSMutableArray *const actions = [NSMutableArray arrayWithCapacity:4];
    if (action0) {
        [actions addObject:action0];
    }
    if (action1) {
        [actions addObject:action1];
    }
    if (action2) {
        [actions addObject:action2];
    }
    if (action3) {
        [actions addObject:action3];
    }
    [category setActions:actions forContext:UIUserNotificationActionContextDefault];
}

- (void)setNotificationHandler:(void(^const)(NSString *identifier, UILocalNotification *n))handler
       forActionWithIdentifier:(NSString *const)identifier
{
    NSParameterAssert(identifier);
    if (handler) {
        void(^const handlerCopy)(NSString *, UILocalNotification *) = [handler copy];
        [self.actionHandlers setObject:handlerCopy forKey:identifier];
    } else {
        [self.actionHandlers removeObjectForKey:identifier];
    }
}

- (UILocalNotification *)buildNotificationWithDate:(NSDate *const)fireDate
                                          timeZone:(BOOL const)timeZone
                                          category:(NSString *const)category
                                          userInfo:(NSDictionary *const)userInfo
{
    NSParameterAssert(fireDate);
    UILocalNotification *const notification = [[UILocalNotification alloc] init];
    notification.fireDate = fireDate;
    if (timeZone) {
        notification.timeZone = self.defaultTimeZone;
    }
    notification.category = category;
    notification.userInfo = userInfo;
    return notification;
}

- (UILocalNotification *)buildNotificationWithInterval:(NSTimeInterval)fireInterval
                                              category:(NSString *)category
                                              userInfo:(NSDictionary *)userInfo
{
    NSParameterAssert(fireInterval >= 0);
    NSDate *const fireDate = [NSDate dateWithTimeIntervalSinceNow:fireInterval];
    return [self buildNotificationWithDate:fireDate
                                  timeZone:NO
                                  category:category
                                  userInfo:userInfo];
}

- (UILocalNotification *)buildNotificationWithRegion:(CLRegion *const)fireRegion
                                        triggersOnce:(BOOL const)regionTriggersOnce
                                            category:(NSString *const)category
                                            userInfo:(NSDictionary *const)userInfo
{
    NSParameterAssert(fireRegion);
    UILocalNotification *const notification = [[UILocalNotification alloc] init];
    notification.region = fireRegion;
    notification.regionTriggersOnce = regionTriggersOnce;
    notification.category = category;
    notification.userInfo = userInfo;
    return notification;
}

- (void)customizeNotificationRepeat:(UILocalNotification *const)notification
                           interval:(NSCalendarUnit const)calendarUnit
{
    NSParameterAssert(notification);
    notification.repeatInterval = calendarUnit;
    notification.repeatCalendar = self.defaultCalendar;
}

- (void)customizeNotificationAlert:(UILocalNotification *const)notification
                             title:(NSString *const)alertTitle
                              body:(NSString *const)alertBody
                            action:(NSString *const)alertAction
                       launchImage:(NSString *const)alertLaunchImage
{
    NSParameterAssert(notification);
    if ([notification respondsToSelector:@selector(setAlertTitle:)]) {
        notification.alertTitle = alertTitle;
    } else if (alertTitle) {
        NSLog(@"setAlertTitle: not supported");
    }
    notification.alertBody = alertBody;
    notification.alertAction = alertAction;
    notification.hasAction = (alertAction.length > 0);
    notification.alertLaunchImage = alertLaunchImage;
}

- (void)customizeNotification:(UILocalNotification *const)notification
                 appIconBadge:(NSInteger const)badgeNumber
                        sound:(BOOL const)hasSound
{
    NSParameterAssert(notification);
    notification.applicationIconBadgeNumber = badgeNumber;
    if (hasSound) {
        notification.soundName = self.defaultSoundName;
    }
}

- (void)presentNotificationNow:(UILocalNotification *const)notification
{
    NSParameterAssert(notification);
    if (!NSThread.isMainThread) {
        NSLog(@"presenting notification from a thread other than the main thread");
    }
    UIApplication *const application = self.defaultApplication;
    [application presentLocalNotificationNow:notification];
}

- (void)scheduleNotification:(UILocalNotification *const)notification
{
    NSParameterAssert(notification);
    UIApplication *const application = self.defaultApplication;
    [application scheduleLocalNotification:notification];
}

- (NSArray *)scheduledNotifications
{
    UIApplication *const application = self.defaultApplication;
    NSArray *const localNotifications = application.scheduledLocalNotifications;
    return (localNotifications ?: @[]);
}

- (void)cancelNotification:(UILocalNotification *const)notification
{
    UIApplication *const application = self.defaultApplication;
    if (notification) {
        [application cancelLocalNotification:notification];
    }
}

- (void)cancelAllNotifications
{
    UIApplication *const application = self.defaultApplication;
    [application cancelAllLocalNotifications];
}

#pragma mark Accessors

- (void)setDefaultApplication:(UIApplication *const)defaultApplication
{
    [self willChangeValueForKey:@"defaultApplication"];
    _defaultApplication = defaultApplication;
    if (![defaultApplication isEqual:UIApplication.sharedApplication]) {
        NSLog(@"using %p instead of UIApplication.sharedApplication", defaultApplication);
    }
    [self didChangeValueForKey:@"defaultApplication"];
    
}

#pragma mark - NSObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        _defaultApplication = UIApplication.sharedApplication;
        _defaultTimeZone = NSTimeZone.defaultTimeZone;
        _defaultCalendar = NSCalendar.autoupdatingCurrentCalendar;
        _defaultSoundName = UILocalNotificationDefaultSoundName;
        _actionHandlers = NSMutableDictionary.dictionary;
        NSUserDefaults *const userDefaults = NSUserDefaults.standardUserDefaults;
        _hasRegisteredNotifications = ([userDefaults boolForKey:kMRUserNotificationsRegisteredKey]
                                       || self.isRegisteredForNotifications);
    }
    return self;
}

@end


#pragma mark - MRLocalNotificationFacade (UIUserNotificationSettings) -


@implementation MRLocalNotificationFacade (UIUserNotificationSettings)

- (void)registerForNotificationWithBadges:(BOOL const)badgeType
                                   alerts:(BOOL const)alertType
                                   sounds:(BOOL const)soundType
                               categories:(NSSet *const)categories
{
    UIUserNotificationType types = UIUserNotificationTypeNone;
    if (badgeType) {
        types |= UIUserNotificationTypeBadge;
    }
    if (alertType) {
        types |= UIUserNotificationTypeAlert;
    }
    if (soundType) {
        types |= UIUserNotificationTypeSound;
    }
    UIUserNotificationSettings *const settings =
    [UIUserNotificationSettings settingsForTypes:types
                                      categories:categories];
    UIApplication *const application = self.defaultApplication;
    [application registerUserNotificationSettings:settings];
}

- (UIUserNotificationSettings *)currentUserNotificationSettings
{
    UIApplication *const application = self.defaultApplication;
    UIUserNotificationSettings *const settings = application.currentUserNotificationSettings;
    return settings;
}

- (UIUserNotificationCategory *)getCategoryForIdentifier:(NSString *const)categoryIdentifier
                            fromUserNotificationSettings:(UIUserNotificationSettings *const)notificationSettings;
{
    NSSet *const categories = notificationSettings.categories;
    for (UIUserNotificationCategory *const category in categories) {
        if ([category.identifier isEqual:categoryIdentifier]) {
            return category;
        }
    }
    return nil;
}

- (BOOL)isRegisteredForNotifications
{
    UIUserNotificationSettings *const settings = self.currentUserNotificationSettings;
    UIUserNotificationType const types = settings.types;
    return (types != UIUserNotificationTypeNone);
}

- (BOOL)isBadgeTypeAllowed
{
    UIUserNotificationSettings *const settings = self.currentUserNotificationSettings;
    return (settings.types & UIUserNotificationTypeBadge) == UIUserNotificationTypeBadge;
}

- (BOOL)isSoundTypeAllowed
{
    UIUserNotificationSettings *const settings = self.currentUserNotificationSettings;
    return (settings.types & UIUserNotificationTypeSound) == UIUserNotificationTypeSound;
}

- (BOOL)isAlertTypeAllowed
{
    UIUserNotificationSettings *const settings = self.currentUserNotificationSettings;
    return (settings.types & UIUserNotificationTypeAlert) == UIUserNotificationTypeAlert;
}

@end


#pragma mark - MRLocalNotificationFacade (UIAlertController) -


@implementation MRLocalNotificationFacade (UIAlertController)

- (UIAlertController *)buildAlertControlForNotification:(UILocalNotification *const)notification
{
    NSParameterAssert(notification);
    NSBundle *const mainBundle = NSBundle.mainBundle;
    NSDictionary *const localizedInfoDictionary = mainBundle.localizedInfoDictionary;
    NSString *const bundleName =localizedInfoDictionary[(NSString *)kCFBundleNameKey];
    NSString *const alertBody = notification.alertBody;
    UIAlertControllerStyle const preferredStyle = UIAlertControllerStyleAlert;
    UIAlertController *const alert = [UIAlertController alertControllerWithTitle:bundleName
                                                                         message:alertBody
                                                                  preferredStyle:preferredStyle];
    UIUserNotificationSettings *const settings = self.currentUserNotificationSettings;
    NSString *const categoryIdentifier = notification.category;
    UIUserNotificationCategory *const category = [self getCategoryForIdentifier:categoryIdentifier
                                                   fromUserNotificationSettings:settings];
    NSArray *const actions = [category actionsForContext:UIUserNotificationActionContextDefault];
    __weak typeof(self) welf = self;
    for (UIUserNotificationAction *const notificationAction in actions) {
        UIAlertAction *const alertAction =
        [UIAlertAction actionWithTitle:notificationAction.title
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *const alertAction) {
                                   [welf handleActionWithIdentifier:notificationAction.identifier
                                               forLocalNotification:notification
                                                  completionHandler:nil];
                               }];
        [alert addAction:alertAction];
    }
    UIAlertAction *const cancelAction =
    [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                             style:UIAlertActionStyleCancel
                           handler:
     ^(UIAlertAction *const action) {
         void(^const onCancel)(UILocalNotification *) = welf.onDidCancelNotificationAlert;
         if (onCancel) {
             onCancel(notification);
         }
     }];
    [alert addAction:cancelAction];
    return alert;
}

- (void)showAlertController:(UIAlertController *const)alert
{
    NSParameterAssert(alert);
    UIViewController *presentingViewController = self.defaultAlertPresenter;
    if (presentingViewController == nil) {
        UIApplication *const application = self.defaultApplication;
        UIWindow *const window = [[UIWindow alloc] initWithFrame:application.keyWindow.frame];
        window.windowLevel = UIWindowLevelAlert;
        presentingViewController = MRLocalNotificationFacadeAlertViewController_.new;
        window.rootViewController = presentingViewController;
        window.hidden = NO;
    }
    [presentingViewController presentViewController:alert animated:YES completion:nil];
}

@end


#pragma mark - MRLocalNotificationFacade (UIApplication) -


@implementation MRLocalNotificationFacade (UIApplication)

- (UILocalNotification *)getNotificationFromLaunchOptions:(NSDictionary *const)launchOptions
{
    UILocalNotification *notification;
    id const candidate = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];
    if ([candidate isKindOfClass:UILocalNotification.class]) {
        notification = candidate;
    }
    return notification;
}

- (NSInteger)applicationIconBadgeNumber
{
    UIApplication *const application = self.defaultApplication;
    return application.applicationIconBadgeNumber;
}

- (void)setApplicationIconBadgeNumber:(NSInteger const)applicationIconBadgeNumber
{
    UIApplication *const application = self.defaultApplication;
    application.applicationIconBadgeNumber = applicationIconBadgeNumber;
}

#pragma mark Private

- (void)mr_setHasRegisteredLocalNotifications
{
    NSUserDefaults *const userDefaults = NSUserDefaults.standardUserDefaults;
    [userDefaults setBool:YES forKey:kMRUserNotificationsRegisteredKey];
    [userDefaults synchronize];
    self.hasRegisteredNotifications = YES;
}

#pragma mark - UIApplicationDelegate

- (void)handleDidRegisterUserNotificationSettings:(UIUserNotificationSettings *const)settings
{
    if (settings == nil) {
        return;
    }
    [self mr_setHasRegisteredLocalNotifications];
}

- (void)handleDidReceiveLocalNotification:(UILocalNotification *const)notification
{
    if (notification == nil) {
        return;
    }
    void(^const handler)(UILocalNotification *, BOOL *) = self.onDidReceiveNotification;
    UIApplication *const application = self.defaultApplication;
    BOOL shouldShowAlert = application.applicationState == UIApplicationStateActive;
    if (handler) {
        handler(notification, &shouldShowAlert);
    }
    if (shouldShowAlert) {
        UIAlertController *const alert = [self buildAlertControlForNotification:notification];
        [self showAlertController:alert];
    }
}

- (void)handleActionWithIdentifier:(NSString *const)identifier
              forLocalNotification:(UILocalNotification *const)notification
                 completionHandler:(void (^const)())completionHandler
{
    if (identifier && notification) {
        void(^const handler)(NSString *, UILocalNotification *) = self.actionHandlers[identifier];
        if (handler) {
            handler(identifier, notification);
        }
    }
    if (completionHandler) {
        completionHandler();
    }
}

@end


#pragma mark - MRLocalNotificationFacade (NSDate) -


@implementation MRLocalNotificationFacade (NSDate)

- (NSDate *)buildDateWithDay:(NSInteger const)day
                       month:(NSInteger const)month
                        year:(NSInteger const)year
                        hour:(NSInteger const)hour
                      minute:(NSInteger const)minute
                      second:(NSInteger const)second
{
    NSCalendar *const calendar = self.defaultCalendar;
    calendar.timeZone = self.defaultTimeZone;
    NSDateComponents *const dateComponents = [[NSDateComponents alloc] init];
    dateComponents.day = day;
    dateComponents.month = month;
    dateComponents.year = year;
    dateComponents.hour = hour;
    dateComponents.minute = minute;
    dateComponents.second = second;
    NSDate *const date = [calendar dateFromComponents:dateComponents];
    return date;
}

- (NSDate *)convertDateToDefaultTimeZone:(NSDate *const)gmtDate
{
    NSParameterAssert(gmtDate);
    NSTimeZone *const timeZone = self.defaultTimeZone;
    NSDate *const timeDate = [self mr_convertDate:gmtDate
                                       toTimeZone:timeZone
                                          reverse:NO];
    return timeDate;
}

- (NSDate *)convertDateToGMT:(NSDate *const)timeDate
{
    NSParameterAssert(timeDate);
    NSTimeZone *const timeZone = self.defaultTimeZone;
    NSDate *const gmtDate = [self mr_convertDate:timeDate
                                      toTimeZone:timeZone
                                         reverse:YES];
    return gmtDate;
}

- (void)date:(NSDate *const)date
      getDay:(NSInteger *const)day
       month:(NSInteger *const)month
        year:(NSInteger *const)year
        hour:(NSInteger *const)hour
      minute:(NSInteger *const)minute
      second:(NSInteger *const)second
{
    NSParameterAssert(date);
    NSCalendar *const calendar = self.defaultCalendar;
    NSCalendarUnit const mask = (NSCalendarUnitSecond |
                                 NSCalendarUnitMinute |
                                 NSCalendarUnitHour   |
                                 NSCalendarUnitDay    |
                                 NSCalendarUnitMonth  |
                                 NSCalendarUnitYear);
    NSDateComponents *const components = [calendar components:mask
                                                     fromDate:date];
    if (second) {
        *second = components.second;
    }
    if (minute) {
        *minute = components.minute;
    }
    if (hour) {
        *hour = components.hour;
    }
    if (day) {
        *day = components.day;
    }
    if (month) {
        *month = components.month;
    }
    if (year) {
        *year = components.year;
    }
}

- (NSDate *)getGMTFireDateFromNotification:(UILocalNotification *const)notification
{
    NSParameterAssert(notification);
    NSDate *gmtDate;
    NSTimeZone *const timeZone = notification.timeZone;
    NSDate *const fireDate = notification.fireDate;
    if (timeZone) {
        gmtDate = [self mr_convertDate:fireDate
                            toTimeZone:timeZone
                               reverse:YES];
    } else {
        gmtDate = notification.fireDate;
    }
    return gmtDate;
}

#pragma mark Private

- (NSDate *)mr_convertDate:(NSDate *const)date
                toTimeZone:(NSTimeZone *const)timeZone
                   reverse:(BOOL const)reverse
{
    NSParameterAssert(date);
    NSParameterAssert(timeZone);
    NSInteger const seconds = [timeZone secondsFromGMTForDate:date];
    NSInteger const signedSeconds = (reverse ? -1 : 1)*seconds;
    NSDate *const convertedDate = [NSDate dateWithTimeInterval:signedSeconds
                                                     sinceDate:date];
    return convertedDate;
}

@end


#pragma mark - MRLocalNotificationFacade (NSErrorRecoveryAttempting) -


@implementation MRLocalNotificationFacade (NSErrorRecoveryAttempting)

- (BOOL)presentNotificationNow:(UILocalNotification *const)notification
                     withError:(NSError **const)errorPtr
{
    BOOL const recoverable = [self canPresentNotificationNow:notification
                                                       error:errorPtr];
    if (recoverable) {
        UIApplication *const application = self.defaultApplication;
        switch (application.applicationState) {
            case UIApplicationStateActive:
                NSLog(@"presenting notification in active state");
                break;
            case UIApplicationStateInactive:
                NSLog(@"presenting notification in inactive state");
                break;
            case UIApplicationStateBackground:
                // expected case
                break;
        }
        [self presentNotificationNow:notification];
    }
    return recoverable;
}

- (BOOL)canPresentNotificationNow:(UILocalNotification *const)notification
                            error:(NSError **const)errorPtr
{
    BOOL const canSchedule = [self mr_isNotificationValid:notification
                                             withRecovery:NO
                                                    error:errorPtr];
    return canSchedule;
}

- (BOOL)scheduledNotificationsContainsNotification:(UILocalNotification *const)notification
{
    NSParameterAssert(notification);
    NSArray *const scheduledNotifications = self.scheduledNotifications;
    for (UILocalNotification *const scheduledNotification in scheduledNotifications) {
        if ([scheduledNotification isEqual:notification]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)scheduleNotification:(UILocalNotification *const)notification
                   withError:(NSError **const)errorPtr
{
    BOOL const recoverable = [self canScheduleNotification:notification
                                              withRecovery:YES
                                                     error:errorPtr];
    if (recoverable) {
        [self scheduleNotification:notification];
        if (![self scheduledNotificationsContainsNotification:notification]) {
            NSLog(@"notification not scheduled yet");
        }
    }
    return recoverable;
}

- (BOOL)canScheduleNotification:(UILocalNotification *const)notification
                   withRecovery:(BOOL const)recovery
                          error:(NSError **const)errorPtr
{
    NSError *error;
    BOOL recoverable = [self mr_isNotificationValid:notification
                                       withRecovery:recovery
                                              error:&error];
    if (recoverable && [self getGMTFireDateFromNotification:notification].timeIntervalSinceNow < 0) {
        recoverable = [self mr_buildError:&error
                                 withCode:MRLocalNotificationErrorInvalidDate];
    }
    if (recoverable && notification.region == nil && notification.fireDate == nil) {
        recoverable = [self mr_buildError:&error
                                 withCode:MRLocalNotificationErrorMissingDate];
    }
    if (recoverable && [self scheduledNotificationsContainsNotification:notification]) {
        recoverable = [self mr_buildError:&error
                                 withCode:MRLocalNotificationErrorAlreadyScheduled];
    }
    if (error && errorPtr) {
        *errorPtr = error;
    }
    BOOL const canSchedule = (recovery ? recoverable : error == nil);
    return canSchedule;
}

- (UIAlertController *)buildAlertControlForError:(NSError *const)error
{
    NSParameterAssert(error);
    NSError *const underlyingError = error.userInfo[NSUnderlyingErrorKey];
    NSString *const title = error.localizedDescription ?:
                            underlyingError.localizedDescription;
    NSMutableString *const message = @"\n".mutableCopy;
    NSString *const failureReason = (error.localizedFailureReason           ?:
                                     underlyingError.localizedFailureReason);
    if (failureReason.length > 0) {
        [message appendString:failureReason];
        [message appendString:@"\n"];
    }
    NSString *const recoverySuggestion = error.localizedRecoverySuggestion;
    if (recoverySuggestion) {
        [message appendString:@"\n"];
        [message appendString:recoverySuggestion];
    }
    UIAlertControllerStyle const preferredStyle = UIAlertControllerStyleAlert;
    UIAlertController *const alert = [UIAlertController alertControllerWithTitle:title
                                                                         message:message
                                                                  preferredStyle:preferredStyle];
    NSArray *const recoveryOptions = error.localizedRecoveryOptions;
    NSObject *const recoveryAttempter = error.recoveryAttempter;
    __weak typeof(self) welf = self;
    NSInteger optionIndex = 0;
    for (NSString *const recoveryOption in recoveryOptions) {
        UIAlertAction *const alertAction =
        [UIAlertAction actionWithTitle:recoveryOption
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *const alertAction) {
                                   [recoveryAttempter attemptRecoveryFromError:error
                                                                   optionIndex:optionIndex];
                               }];
        [alert addAction:alertAction];
        optionIndex += 1;
    }
    NSString *const helpAnchor = error.helpAnchor;
    if (helpAnchor.length > 0) {
        UIAlertAction *const helpAction =
        [UIAlertAction actionWithTitle:NSLocalizedString(@"Help", nil)
                                 style:UIAlertActionStyleDefault
                               handler:
         ^(UIAlertAction *const action) {
             UIAlertController *const helpAlert =
             [UIAlertController alertControllerWithTitle:nil
                                                 message:helpAnchor
                                          preferredStyle:preferredStyle];
             UIAlertAction *const cancelHelpAction =
             [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                      style:UIAlertActionStyleCancel
                                    handler:
              ^(UIAlertAction *const action) {
                  [self showAlertController:alert];
              }];
             [helpAlert addAction:cancelHelpAction];
             [self showAlertController:helpAlert];
         }];
        [alert addAction:helpAction];
    }
    UIAlertAction *const cancelAction =
    [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                             style:UIAlertActionStyleCancel
                           handler:
     ^(UIAlertAction *const action) {
         void(^const onCancel)(NSError *) = welf.onDidCancelErrorAlert;
         if (onCancel) {
             onCancel(error);
         }
     }];
    [alert addAction:cancelAction];
    return alert;
}

#pragma mark Private

- (BOOL)mr_isNotificationValid:(UILocalNotification *const)notification
                  withRecovery:(BOOL const)recovery
                         error:(NSError **const)errorPtr
{
    NSError *error;
    BOOL recoverable = YES;
    if (notification == nil) {
        recoverable = [self mr_buildError:&error
                                 withCode:MRLocalNotificationErrorNilObject];
    }
    if (recoverable && ![notification isKindOfClass:UILocalNotification.class]) {
        recoverable = [self mr_buildError:&error
                                 withCode:MRLocalNotificationErrorInvalidObject];
    }
    if (recoverable && notification.alertBody.length == 0 && notification.applicationIconBadgeNumber <= 0) {
        recoverable = [self mr_buildError:&error
                                 withCode:MRLocalNotificationErrorMissingAlertBody];
    }
    if (recoverable && notification.soundName && !self.isSoundTypeAllowed) {
        recoverable = [self mr_buildError:&error
                                 withCode:MRLocalNotificationErrorSoundNotAllowed];
    }
    if (recoverable && notification.applicationIconBadgeNumber != 0 && !self.isBadgeTypeAllowed) {
        recoverable = [self mr_buildError:&error
                                 withCode:MRLocalNotificationErrorBadgeNotAllowed];
    }
    if (recoverable && notification.alertBody && !self.isAlertTypeAllowed) {
        recoverable = [self mr_buildError:&error
                                 withCode:MRLocalNotificationErrorAlertNotAllowed];
    }
    if (recoverable && !self.isRegisteredForNotifications) {
        recoverable = [self mr_buildError:&error
                                 withCode:MRLocalNotificationErrorNoneAllowed];
    }
    if (recoverable) {
        NSString *const category = notification.category;
        UIUserNotificationSettings *const settings = self.currentUserNotificationSettings;
        if (category && [self getCategoryForIdentifier:category
                          fromUserNotificationSettings:settings] == nil) {
            recoverable = [self mr_buildError:&error
                                     withCode:MRLocalNotificationErrorCategoryNotRegistered];
        }
    }
    if (error && errorPtr) {
        *errorPtr = error;
    }
    BOOL const isValid = (recovery ? recoverable : error == nil);
    return isValid;
}

- (BOOL)mr_buildError:(NSError **const)errorPtr withCode:(MRLocalNotificationErrorCode const)code
{
    BOOL validNotification;
    NSString *description;
    NSString *recoverySuggestion;
    NSArray *recoveryOptions;
    UIApplication *const application = self.defaultApplication;
    BOOL contactSupport = NO;
    NSURL *recoveryURL;
    if ([self mr_isNonRecoverableErrorCode:code]) {
        validNotification = NO;
        description = NSLocalizedString(@"Error scheduling notification", nil);
        NSURL *const contactSupportURL = self.contactSupportURL;
        contactSupport = (contactSupportURL && [application canOpenURL:contactSupportURL]);
    } else {
        validNotification = YES;
        description = NSLocalizedString(@"Local notifications", nil);
        if (code == MRLocalNotificationErrorCategoryNotRegistered) {
            NSURL *const contactSupportURL = self.contactSupportURL;
            contactSupport = (contactSupportURL && [application canOpenURL:contactSupportURL]);
        }
    }
    if (contactSupport) {
        recoveryOptions = @[ NSLocalizedString(@"Contact Support", nil) ];
        recoverySuggestion = NSLocalizedString(@"If the problem persists, please contact support.", nil);
        recoveryURL = self.contactSupportURL;
    } else {
        recoverySuggestion = NSLocalizedString(@"Please go to Settings and enable missing notification types.", nil);
        recoveryOptions = @[ NSLocalizedString(@"Settings", nil) ];
        recoveryURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    }
    NSString *const failureReason = [self mr_localizedFailureReasonForCode:code];
    NSDictionary * const userInfo = @{ NSLocalizedDescriptionKey: description,
                                       NSLocalizedFailureReasonErrorKey: failureReason,
                                       NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion,
                                       NSLocalizedRecoveryOptionsErrorKey: recoveryOptions,
                                       NSRecoveryAttempterErrorKey: self,
                                       MRRecoveryURLErrorKey: recoveryURL };
    NSError *const error = [NSError errorWithDomain:MRLocalNotificationErrorDomain
                                               code:code
                                           userInfo:userInfo];
    if (errorPtr) {
        *errorPtr = error;
    }
    return validNotification;
}

- (BOOL)mr_isNonRecoverableErrorCode:(MRLocalNotificationErrorCode const)code
{
    return (code == MRLocalNotificationErrorUnknown             ||
            code == MRLocalNotificationErrorNilObject           ||
            code == MRLocalNotificationErrorInvalidObject       ||
            code == MRLocalNotificationErrorInvalidDate         ||
            code == MRLocalNotificationErrorMissingDate         ||
            code == MRLocalNotificationErrorAlreadyScheduled    ||
            code == MRLocalNotificationErrorMissingAlertBody    );
}

- (NSString *)mr_localizedFailureReasonForCode:(MRLocalNotificationErrorCode const)code
{
    NSString *failureReason;
    if (code == MRLocalNotificationErrorNoneAllowed) {
        failureReason = NSLocalizedString(@"Notifications will not work if you do not enable them in Settings.", nil);
    } else if (code == MRLocalNotificationErrorSoundNotAllowed) {
        failureReason = NSLocalizedString(@"The sounds of the notifications will not be played if you do not allow them in Settings.", nil);
    } else if (code == MRLocalNotificationErrorAlertNotAllowed) {
        failureReason = NSLocalizedString(@"Notifications will not display any alert dialog if you do not allow them in Settings.", nil);
    } else if (code == MRLocalNotificationErrorBadgeNotAllowed) {
        failureReason = NSLocalizedString(@"Notifications will not update application's badge number if you do not allow them in Settings.", nil);
    } else if (code == MRLocalNotificationErrorNilObject) {
        failureReason = NSLocalizedString(@"No notification provided.", nil);
    } else if (code == MRLocalNotificationErrorInvalidDate) {
        failureReason = NSLocalizedString(@"Notification fire date is not valid.", nil);
    } else if (code == MRLocalNotificationErrorMissingDate) {
        failureReason = NSLocalizedString(@"Notification is missing a fire date or region.", nil);
    } else if (code == MRLocalNotificationErrorAlreadyScheduled) {
        failureReason = NSLocalizedString(@"Notification is already scheduled.", nil);
    } else if (code == MRLocalNotificationErrorInvalidObject) {
        failureReason = NSLocalizedString(@"Notification provided is not valid.", nil);
    } else if (code == MRLocalNotificationErrorCategoryNotRegistered) {
        failureReason = NSLocalizedString(@"Notification scheduled, but its actions group is not registered.", nil);
    } else if (code == MRLocalNotificationErrorMissingAlertBody) {
        failureReason = NSLocalizedString(@"Notification is missing an alert body or icon badge number.", nil);
    } else {
        NSAssert(code == MRLocalNotificationErrorUnknown, @"unhandled code");
        failureReason = NSLocalizedString(@"Unknown error.", nil);
    }
    return failureReason;
}

#pragma mark - NSErrorRecoveryAttempting

- (void)setContactSupportURLWithEmailAddress:(NSString *const)emailAddress
                                     subject:(NSString *const)subject
                                        body:(NSString *const)body
{
    NSParameterAssert(emailAddress);
    NSString *const scheme = @"mailto";
    NSMutableString *const url = [NSMutableString stringWithFormat:@"%@:%@", scheme, emailAddress];
    NSMutableArray *const queryComponents = [NSMutableArray arrayWithCapacity:2];
    if (subject.length > 0) {
        [queryComponents addObject:[NSString stringWithFormat:@"subject=%@", subject]];
    }
    if (body.length > 0) {
        [queryComponents addObject:[NSString stringWithFormat:@"body=%@", body]];
    }
    if (queryComponents.count > 0) {
        NSCharacterSet *const charSet = NSCharacterSet.URLQueryAllowedCharacterSet;
        NSString *const query = [queryComponents componentsJoinedByString:@"&"];
        NSString *encodedQuery = [query stringByAddingPercentEncodingWithAllowedCharacters:charSet];
        [url appendFormat:@"?%@", encodedQuery];
    }
    self.contactSupportURL = [NSURL URLWithString:url];
}

- (void)attemptRecoveryFromError:(NSError *const)error
                     optionIndex:(NSUInteger const)recoveryOptionIndex
                        delegate:(id const)target
              didRecoverSelector:(SEL const)didRecoverSelector
                     contextInfo:(void *)contextInfo
{
    NSParameterAssert(error);
    NSParameterAssert(target == nil || didRecoverSelector);
    BOOL const didRecover = [self attemptRecoveryFromError:error optionIndex:recoveryOptionIndex];
    if (target) {
        NSMethodSignature *const signature = [target methodSignatureForSelector:didRecoverSelector];
        NSInvocation *const invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.selector = didRecoverSelector;
        [invocation setArgument:(void *)&didRecover atIndex:2];
        [invocation setArgument:&contextInfo atIndex:3];
        [invocation invokeWithTarget:target];
    }
}

- (BOOL)attemptRecoveryFromError:(NSError *const)error
                     optionIndex:(NSUInteger const)recoveryOptionIndex
{
    
    NSParameterAssert(error);
    BOOL completed = NO;
    NSURL *const URL = error.userInfo[MRRecoveryURLErrorKey];
    UIApplication *const application = self.defaultApplication;
    if (URL && [application canOpenURL:URL]) {
        completed = [application openURL:URL];
    }
    return completed;
}

@end
