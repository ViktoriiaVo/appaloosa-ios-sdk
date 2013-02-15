Appaloosa SDK
=============

Overview
--------

Appaloosa SDK library is a simple library that helps you to:
 
* Auto-update your application stored on [Appaloosa Store](http://www.appaloosa-store.com/) server
* Receive feedback from your users directly from the app (iPhone and iPad)


Requirements
------------

Appaloosa SDK library use ARC and is compatible with iOS 5+.


Integrate Appaloosa SDK with CocoaPods
----------------------------------------

Simply add `pod 'OTAppaloosa', :podspec => "https://raw.github.com/octo-online/appaloosa-ios-sdk/0.2.0/OTAppaloosa.podspec"` in your Podfile.

Refer to [CocoaPods](https://github.com/CocoaPods/CocoaPods) for more information about it.

Integrate Appaloosa SDK the old fashioned way
-----------------------------------------------

Download and import OTAppaloosa sources and its dependancies : [JSONKit](https://github.com/johnezang/JSONKit) and [TPKeyboardAvoiding](https://github.com/michaeltyson/TPKeyboardAvoiding).

Note: JSONKit is not using ARC. Fix its project compiled options with `-fno-objc-arc`.


Check for application update - simple version
-----------------------------------------------

In your AppDelegate.m file, launch the autoupdate when your application starts : 
    1. Import the plugin: `#import "OTAppaloosa.h"`
    2. In method `- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions`, add the following code line:

	[[OTAppaloosaSimpleUpdateService sharedInstance]checkForUpdateWithStoreID:STORE_ID storeToken:STORE\_TOKEN];

Check for application update - clever version
-----------------------------------------------


1. Into your AppDelegate.h file
    1. Add the OTAppaloosaUpdateServiceDelegate into your interface:

            @interface AppDelegate : UIResponder <UIApplicationDelegate, AppaloosaServiceDelegate>

    2. Add an OTAppaloosaUpdateService property:

            @property (nonatomic, strong) AppaloosaService *appaloosaService;

2. Into your AppDelegate.m file (launch of the autoupdate during application start)
    1. Import the plugin: `#import "OTAppaloosa.h"`
    2. Add the OTAppaloosaUpdateService synthesize:

            @synthesize appaloosaService;

	3. Into method `- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions`, add the following code line:

        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        NSString *bundleIDFormatted = [bundleID urlEncodeUsingEncoding:NSUTF8StringEncoding];
        appaloosaService = [[OTAppaloosaUpdateService alloc] initWithDelegate:self];
        [appaloosaService checkForUpdateWithStoreID:STORE\_ID appID:bundleIDFormatted storeToken:STORE_TOKEN];

    4. Call the OTAppaloosaUpdateServiceDelegate method « updateIsAvailableOnAppaloosaStore »:

            - (void)updateIsAvailableOnAppaloosaStore
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update available" message:@"Would you like to update your application?" delegate:self cancelButtonTitle:@"Cancel"                             otherButtonTitles:@"Ok",nil];
                [alert show];
            }

    5. Call the AlertViewDelegate method « alert:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex » to validate or not the update:

            - (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
            {
                if (buttonIndex == 0)
                {
                    NSLog(@"Cancel Update");
                }
                else if (buttonIndex == 1)
                {
                    [self.appaloosaService downloadNewVersionOfTheApp];
                }
            }

Add in-app-feedback to your app
---------------------------------

This SDK provides a fully integrated solution to send feedback to your dev team. In your appDelegate file, add the following line: 

	 [[OTAppaloosaInAppFeedbackManager sharedManager] initializeDefaultFeedbackButtonWithPosition:kFeedbackButtonPositionRightBottom forRecipientsEmailArray:@[@"e.mail@address.com"]];
	
You have 2 possible positions for the default feedback button. If you prefer to use your own button/action to trigger feedback, you can use the following line: 

 	[[OTAppaloosaInAppFeedbackManager sharedManager] presentFeedbackWithRecipientsEmailArray:@[@"e.mail@address.com"]];

To see how to use this feature, take a look at the Example/OTInAppFeedback/ project.

Want some documentation?
------------------------

Appaloosa SDK for iOS use [AppleDoc](https://github.com/tomaz/appledoc) to generate its API's documentation.
