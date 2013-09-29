//
//  CCAppDelegate.m
//  Communicaid2
//
//  Created by Lee Yu Zhou on 29/9/13.
//  Copyright (c) 2013 Lee Yu Zhou. All rights reserved.
//

#import "CCAppDelegate.h"
#import "CCDetailViewController.h"
#import "CCMasterViewController.h"
#import "ATTSpeechKit.h"
#import "SpeechAuth.h"
#import "SpeechConfig.h"
@implementation CCAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
- (void)initializePubNubClient {
    
    [PubNub setDelegate:self];
    
    
    // Subscribe for client connection state change
    // (observe when client will be disconnected)
    [[PNObservationCenter defaultCenter] addClientConnectionStateObserver:self
                                                        withCallbackBlock:^(NSString *origin,
                                                                            BOOL connected,
                                                                            PNError *error) {
                                                            
                                                            if (!connected && error) {
                                                                
                                                                UIAlertView *infoAlertView = [UIAlertView new];
                                                                infoAlertView.title = [NSString stringWithFormat:@"%@(%@)",
                                                                                       [error localizedDescription],
                                                                                       NSStringFromClass([self class])];
                                                                infoAlertView.message = [NSString stringWithFormat:@"Reason:\n%@\nSuggestion:\n%@",
                                                                                         [error localizedFailureReason],
                                                                                         [error localizedRecoverySuggestion]];
                                                                [infoAlertView addButtonWithTitle:@"OK"];
                                                                [infoAlertView show];
                                                            }
                                                        }];
    
    
    // Subscribe application delegate on subscription updates
    // (events when client subscribe on some channel)
    // Subscribe application delegate on subscription updates
    // (events when client subscribe on some channel)
    [[PNObservationCenter defaultCenter] addClientChannelSubscriptionStateObserver:self
                                                                 withCallbackBlock:^(PNSubscriptionProcessState state,
                                                                                     NSArray *channels,
                                                                                     PNError *subscriptionError) {
                                                                     
                                                                     switch (state) {
                                                                             
                                                                         case PNSubscriptionProcessNotSubscribedState:
                                                                             
                                                                             PNLog(PNLogGeneralLevel, self,
                                                                                   @"{BLOCK-P} PubNub client subscription failed with error: %@",
                                                                                   subscriptionError);
                                                                             break;
                                                                             
                                                                         case PNSubscriptionProcessSubscribedState:
                                                                             
                                                                             PNLog(PNLogGeneralLevel, self,
                                                                                   @"{BLOCK-P} PubNub client subscribed on channels: %@",
                                                                                   channels);
                                                                             break;
                                                                             
                                                                         case PNSubscriptionProcessWillRestoreState:
                                                                             
                                                                             PNLog(PNLogGeneralLevel, self,
                                                                                   @"{BLOCK-P} PubNub client will restore subscribed on channels: %@",
                                                                                   channels);
                                                                             break;
                                                                             
                                                                         case PNSubscriptionProcessRestoredState:
                                                                             
                                                                             PNLog(PNLogGeneralLevel, self,
                                                                                   @"{BLOCK-P} PubNub client restores subscribed on channels: %@",
                                                                                   channels);
                                                                             break;
                                                                     }
                                                                 }];
    
    // Subscribe on message arrival events with block
    [[PNObservationCenter defaultCenter] addMessageReceiveObserver:self
                                                         withBlock:^(PNMessage *message) {
                                                             
                                                             PNLog(PNLogGeneralLevel, self, @"{BLOCK-P} PubNubc client received new message: %@",
                                                                   message);
                                                         }];
    
    // Subscribe on presence event arrival events with block
    [[PNObservationCenter defaultCenter] addPresenceEventObserver:self
                                                        withBlock:^(PNPresenceEvent *presenceEvent) {
                                                            
                                                            PNLog(PNLogGeneralLevel, self, @"{BLOCK-P} PubNubc client received new event: %@",
                                                                  presenceEvent);
                                                        }];
    
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:NULL];
    UITabBarController *tabBarController = [sb instantiateViewControllerWithIdentifier:@"TabBar"];
    self.window.rootViewController = tabBarController;
    
    UISplitViewController *splitViewController = [tabBarController viewControllers][0];
    CCDetailViewController *ccDetailViewController = [splitViewController.viewControllers lastObject];
    splitViewController.delegate = (id)ccDetailViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers firstObject];
    navigationController.navigationItem.title = @"Product Categories";
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Communicaid2" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Communicaid2.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
