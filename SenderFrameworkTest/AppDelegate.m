//
//  AppDelegate.m
//  SenderFrameworkTest
//
//  Created by Roman Serga on 13/4/17.
//  Copyright © 2017 Roman Serga. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import <SenderFramework/SenderFramework.h>
#import <SenderFramework/SenderFramework-Swift.h>

@interface AppDelegate ()
{
    NSDate * wakeTime;
}

@property (nonatomic) BOOL isAuthorizationInProgress;
@property (nonatomic, strong) UINavigationController * navigationController;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    self.navigationController = [[UINavigationController alloc] init];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.navigationController.navigationBar setTintColor:[[SenderCore sharedCore].stylePalette mainAccentColor]];

    self.window = [[UIWindow alloc]init];
    self.window.rootViewController = self.navigationController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    /*
     * Configuring SenderCore
     */
    [self configureSenderCore:[SenderCore sharedCore]];
    [SenderCore sharedCore].authorizationDelegate = self;
    [SenderCore sharedCore].authorizationNavigationController = self.navigationController;
    [[SenderCore sharedCore]setUpWithApplication:application];

    /*
     * Creating senderUI of AppDelegate for displaying chat after app was launched from push notification
     */
    self.senderUI = [[SenderUI alloc] initWithRootViewController:self.navigationController];
    /*
     * Setting SenderCore's senderUI for handling global actions like forceOpen
     */
    [SenderCore sharedCore].senderUI = self.senderUI;

#if !(TARGET_IPHONE_SIMULATOR)
    [self turnOnPushNotifications];
#endif

    /*
     * If SenderCore is not authorized, we should authorize first
     * This app authorizes in sender immediately after it was launched.
     * Other apps can authorize in sender wherever they need.
     */
    if (![[SenderCore sharedCore] isAuthorized])
    {
        [self startSenderAuthorization];
    }
    else
    {
        if ([[SenderCore sharedCore] isAuthorized])
        {

            /*
             * SenderCore is authorized. So we just start app as usually
             */
            [self startAppAnimated:NO];

            /*
             * If app was launched after tapping on push, app handles push notification, by displaying chat
             * We shouldn't handle push notifications here is UNUserNotificationCenter was used to register for
             * push notifications
             */
            if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] && ![self isUNUserNotificationCenterAvailable])
                [self.senderUI showChatWithRemoteNotification:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]
                                                     animated:YES
                                                      modally:NO
                                                     delegate:nil];
        }
    }

    return YES;
}

/*
 * Configuring SenderCore with IDs of developer and device
 */
- (void)configureSenderCore:(SenderCore *)senderCore
{
    SenderCoreConfiguration * configuration = [[SenderCoreConfiguration alloc]init];

    configuration.deviceUDID = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    configuration.deviceIMEI = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    configuration.companyID = @"";
    configuration.developerID = @"developerID";
    configuration.developerKey = @"developerKey";
    configuration.apnsString = @"apnsString";
    configuration.googleClientID = @"googleClientID";

    senderCore.configuration = configuration;
}

- (void)startSenderAuthorization
{
    /*
     * We use isAuthorizationInProgress flag in order to not start multiple sender authorization processes
     */
    if (self.isAuthorizationInProgress)
        return;

    if (![[SenderCore sharedCore] isAuthorized])
        self.isAuthorizationInProgress = YES;

    /*
     * Your app must get AuthToken in order to perform SSO authorization.
     * If authToken is not valid, user will be authorized as anonymous user
     */
    [[SenderCore sharedCore] startSSOAuthorizationWithAuthToken:@"AuthToken"];
}

- (void)finishSenderAuthorization
{
    self.isAuthorizationInProgress = NO;
}

- (void)startAppAnimated:(BOOL)animated
{
    /*
     * Starting SenderCore's active network connection.
     * We start not only in applicationDidBecomeActive but also here because network connection won't be start if
     * SenderCore wasn't authorized on applicationDidBecomeActive call.
     */
    [SenderCore sharedCore].isPaused = NO;
    UIStoryboard * mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ViewController * viewController = [mainStoryboard instantiateInitialViewController];
    [self.navigationController setViewControllers:@[viewController] animated:animated];
}

- (void)senderCoreDidFinishAuthorization:(SenderCore *)senderCore
{
    [self finishSenderAuthorization];

    /*
     * Sender authorization was finished. Staring our app
     */
    [self startAppAnimated:YES];
}

- (void)senderCoreDidFailAuthorization:(SenderCore *)senderCore
{
    [self finishSenderAuthorization];
    /*
     * Sender authorization was failed. This app starts sender authorization again.
     * Other apps may handle this differently.
     */
    [self startSenderAuthorization];
}

- (void)senderCoreDidFinishDeauthorization:(SenderCore *)notification
{
    /*
     * Sender has deauthorized. This app starts sender authorization again.
     * Other apps may handle this differently.
     */
    [self finishSenderAuthorization];
    [self startSenderAuthorization];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     * Pausing SenderCore's active network connection
     */
    [SenderCore sharedCore].isPaused = YES;
    /*
     * Setting unread messages count as icon badge number
     */
    NSInteger unreadMessagesNumber = [SenderCore sharedCore].unreadMessagesCounter.unreadMessagesCount;
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:unreadMessagesNumber];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     * Restarting SenderCore's active network connection if sender is authorized
     */
    if ([[SenderCore sharedCore] isAuthorized])
        [SenderCore sharedCore].isPaused = NO;
}

- (void)                application:(UIApplication *)application
handleEventsForBackgroundURLSession:(NSString *)identifier
                  completionHandler:(void (^)())completionHandler
{
    /*
     * Sending backgroundURLSession events to SenderCore because sender uses
     * backgroundURLSessions to load images, videos, etc.
     */
    [[SenderCore sharedCore] application:application
     handleEventsForBackgroundURLSession:identifier
                       completionHandler:completionHandler];
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    //Setting time of wake up in order to check it in application:didReceiveRemoteNotification:fetchCompletionHandler:
    wakeTime = [NSDate date];
}

#pragma mark - Remote Notifications

- (BOOL)isUNUserNotificationCenterAvailable
{
    NSString * currSysVer = [[UIDevice currentDevice] systemVersion];
    return ([currSysVer compare:@"10" options:NSNumericSearch] != NSOrderedAscending);
}

- (void)turnOnPushNotifications
{
    /*
     * If UNUserNotificationCenterAvailable is available, we should use it to register for push notifications
     */
    if ([self isUNUserNotificationCenterAvailable])
    {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        UNAuthorizationOptions options = (UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
        [center requestAuthorizationWithOptions:options
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                  if (!error)
                                  {
                                      [[UIApplication sharedApplication] registerForRemoteNotifications];
                                      [self voipRegistration];
                                  }
                              }];
    }
    else
    {
        [self voipRegistration];
        UIUserNotificationType types = UIUserNotificationTypeAlert |
                UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
        UIUserNotificationSettings * notificationSettings = [UIUserNotificationSettings settingsForTypes:types
                                                                                              categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

/*
 * Registering for voip push notifications
 */
- (void)voipRegistration
{
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    PKPushRegistry * voipRegistry = [[PKPushRegistry alloc] initWithQueue: mainQueue];
    voipRegistry.delegate = self;
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSCharacterSet * dividerCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"<>"];
    NSString * token = [[deviceToken description] stringByTrimmingCharactersInSet: dividerCharacterSet];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    /*
     * App received push notifications token.
     * We should send in to sender, if we want to receive sender's push notifications.
     */
    [[SenderCore sharedCore] setPushToken:token voipToken:[SenderCore sharedCore].voipToken];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
{
    completionHandler(UNNotificationPresentationOptionNone);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void(^)())completionHandler
{
    NSLog(@"Userinfo %@",response.notification.request.content.userInfo);

    /*
     * Handling tap on push notification and show chat
     */
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    if (!response.notification.request.content.userInfo[@"ci"])
        return;

    [self.senderUI showChatWithRemoteNotification:userInfo animated:YES modally:NO delegate:nil];
    completionHandler();
}

- (void)         application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
      fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    /*
     * Push notification was received while app is in background.
     * We first need to send in to SenderCore for processing.
     */
    BOOL senderHasHandledNotification = [[SenderCore sharedCore] application:application
                                                didReceiveRemoteNotification:userInfo
                                                      fetchCompletionHandler:completionHandler];

    /*
     * If Sender has handled notification, checking application state and wakeTime in order to detect
     * whether user has tapped on push notification.
     */
    if (senderHasHandledNotification)
    {
        if (![self isUNUserNotificationCenterAvailable] && application.applicationState != UIApplicationStateBackground)

        {
            /*
             * It it's been less than 0.1 seconds since wakeTime, it means
             * app was opened after user tapped on push notification
             *
             * https://stackoverflow.com/a/38645687
             */
            if ([[NSDate date] timeIntervalSinceDate:wakeTime] < 0.1)
                [self.senderUI showChatWithRemoteNotification:userInfo animated:YES modally:NO delegate:nil];
        }
    }
    else
    {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

#ifdef __IPHONE_8_0
- (void)                application:(UIApplication *)application
didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}
#endif

- (void)    pushRegistry:(PKPushRegistry *)registry
didUpdatePushCredentials:(PKPushCredentials *)credentials
                 forType:(NSString *)type
{
    /*
     * App received voip push token. We should send it to sender
     */
    NSString * strToken = [[NSString stringWithFormat:@"%@",credentials.token]stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    [[NSUserDefaults standardUserDefaults] setObject:strToken forKey:@"VoipToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSString * voipToken = [strToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    [[SenderCore sharedCore] setPushToken:[SenderCore sharedCore].pushToken voipToken:voipToken];
}


- (void)             pushRegistry:(PKPushRegistry *)registry
didReceiveIncomingPushWithPayload:(PKPushPayload *)payload
                          forType:(NSString *)type
{
    [[SenderCore sharedCore]pushRegistry:registry didReceiveIncomingPushWithPayload:payload forType:type];
}

@end
