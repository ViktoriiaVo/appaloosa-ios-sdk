// Copyright 2013 OCTO Technology
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//
//  OTAppaloosaInAppFeedbackManager.m
//
//  Created by Maxence Walbrou on 06/02/13.
//  Copyright (c) 2013 OCTO. All rights reserved.
//

#import "OTAppaloosaInAppFeedbackManager.h"


// Controllers :
#import "OTAppaloosaInAppFeedbackViewController.h"

// Misc :
#import <QuartzCore/QuartzCore.h>

// Utils :
#import "UIViewController+CurrentPresentedController.h"


// Constants :
static const CGFloat kFeedbackButtonRightMargin = 20;
static const CGFloat kFeedbackButtonBottomMargin = 70;

static const CGFloat kFeedbackButtonWidth = 35;
static const CGFloat kFeedbackButtonHeight = 35;

static const CGFloat kAnimationDuration = 0.9;

@interface OTAppaloosaInAppFeedbackManager ()

- (void)initializeDefaultFeedbackButtonWithPosition:(FeedbackButtonPosition)position;

- (void)onFeedbackButtonTap;

+ (UIImage *)getScreenshotImageFromCurrentScreen;
- (void)triggerFeedbackWithRecipientsEmailArray:(NSArray *)emailsArray andFeedbackButton:(UIButton *)feedbackButton;
+ (UIView *)getApplicationWindowView;

- (void)onOrientationChange;
- (void)updateFeedbackButtonFrame;

@end


@implementation OTAppaloosaInAppFeedbackManager


/**************************************************************************************************/
#pragma mark - Singleton

static OTAppaloosaInAppFeedbackManager *manager;

+ (OTAppaloosaInAppFeedbackManager *)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    
    return manager;
}

/**************************************************************************************************/
#pragma mark - Birth & Death


- (id)init
{
    self = [super init];
    if (self)
    {      
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


/**************************************************************************************************/
#pragma mark - UI

- (void)showDefaultFeedbackButton:(BOOL)shouldShow
{
    if (!self.feedbackButton)
    {
        NSLog(@"ERROR : Default feedback button must be initalized before changing its visibility");
    }
    else
    {
        [self.feedbackButton setHidden:!shouldShow];
    }
}


/**************************************************************************************************/
#pragma mark - IBActions

- (void)onFeedbackButtonTap
{
    [self triggerFeedbackWithRecipientsEmailArray:self.recipientsEmailArray
                                andFeedbackButton:self.feedbackButton];
}


/**************************************************************************************************/
#pragma mark - Feedback 


- (void)initializeDefaultFeedbackButtonWithPosition:(FeedbackButtonPosition)position
                            forRecipientsEmailArray:(NSArray *)emailsArray
{
    [self initializeDefaultFeedbackButtonWithPosition:position];
    self.recipientsEmailArray = emailsArray;
    [self showDefaultFeedbackButton:YES];
}


- (void)presentFeedbackWithRecipientsEmailArray:(NSArray *)emailsArray
{
    [self triggerFeedbackWithRecipientsEmailArray:emailsArray andFeedbackButton:self.feedbackButton];
}


- (void)triggerFeedbackWithRecipientsEmailArray:(NSArray *)emailsArray andFeedbackButton:(UIButton *)feedbackButton
{
    // take screenshot :
    [self.feedbackButton setAlpha:0];
    UIImage *screenshotImage = [OTAppaloosaInAppFeedbackManager getScreenshotImageFromCurrentScreen];
    [self.feedbackButton setAlpha:1];
    
    // display white blink screen (to copy iOS screenshot effect) before opening feedback controller :
    UIView *whiteView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [whiteView setBackgroundColor:[UIColor whiteColor]];
    UIView *windowView = [OTAppaloosaInAppFeedbackManager getApplicationWindowView];
    [windowView addSubview:whiteView];
    [UIView animateWithDuration:kAnimationDuration animations:^
     {
         [whiteView setAlpha:0];
     }
                     completion:^(BOOL finished)
     {
         [whiteView removeFromSuperview];
         
         // open feedback controller :
         OTAppaloosaInAppFeedbackViewController *feedbackViewController =
            [[OTAppaloosaInAppFeedbackViewController alloc] initWithFeedbackButton:feedbackButton
                                                              recipientsEmailArray:emailsArray
                                                                andScreenshotImage:screenshotImage];
         
         if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
         {
             [feedbackViewController setModalPresentationStyle:UIModalPresentationFormSheet];
         }
         
         [[UIViewController currentPresentedController] presentModalViewController:feedbackViewController animated:YES];
     }];
}

/**************************************************************************************************/
#pragma mark - Private


/**
 * @brief Create the default feedback button and add it as subview on application window
 */
- (void)initializeDefaultFeedbackButtonWithPosition:(FeedbackButtonPosition)position
{
    UIView *windowView = [OTAppaloosaInAppFeedbackManager getApplicationWindowView];

    self.feedbackButton = [[UIButton alloc] init];
    NSString *imageName = (position == kFeedbackButtonPositionBottomRight ? @"btn_bottomFeedback" : @"btn_rightFeedback");
    [self.feedbackButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [self.feedbackButton addTarget:self action:@selector(onFeedbackButtonTap) forControlEvents:UIControlEventTouchUpInside];
    [self.feedbackButton setHidden:YES]; // button is hidden by default
    
    [windowView addSubview:self.feedbackButton];
    
    self.feedbackButtonPosition = position;
    
    [self updateFeedbackButtonFrame];
}


+ (UIImage *)getScreenshotImageFromCurrentScreen
{
    UIView *viewToCopy = [[UIViewController currentPresentedController] view];
    CGRect rect = [viewToCopy bounds];
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
    [[viewToCopy layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return screenImage;
}

/**
 * @return First window's view
 */
+ (UIView *)getApplicationWindowView
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (!window)
    {
        window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
    }
    
    return window;
}

- (void)onOrientationChange
{
    [self updateFeedbackButtonFrame];
}


/**
 * @brief Update feedback button frame switch device orientation.
 */
- (void)updateFeedbackButtonFrame
{
    BOOL shouldShowButton = (self.feedbackButton.alpha != 0);
    
    // hide button to prevent rotation glitch (button stays at the same place during rotation) :
    [self.feedbackButton setAlpha:0];
    
    // recover device orientation :
    UIView *windowView = [OTAppaloosaInAppFeedbackManager getApplicationWindowView];
    UIDeviceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    BOOL isInLandscapeMode = (UIDeviceOrientationIsLandscape(currentOrientation));
    
    // calculate new origin point and rotation angle for feedback button switch orientation :
    CGFloat x;
    CGFloat y;
    CGFloat rotationAngle;
    if (isInLandscapeMode)
    {
        if (currentOrientation == UIDeviceOrientationLandscapeRight)
        {
            if (self.feedbackButtonPosition == kFeedbackButtonPositionBottomRight)
            {
                x = windowView.frame.size.width - kFeedbackButtonHeight;
                y = kFeedbackButtonRightMargin;
            }
            else
            {
                x = windowView.frame.size.width - kFeedbackButtonBottomMargin - kFeedbackButtonHeight;
                y = 0;
            }
            rotationAngle = -M_PI / 2;
        }
        else
        {
            if (self.feedbackButtonPosition == kFeedbackButtonPositionBottomRight)
            {
                x = 0;
                y = windowView.frame.size.height - kFeedbackButtonWidth - kFeedbackButtonRightMargin;
            }
            else
            {
                x = kFeedbackButtonBottomMargin;
                y = windowView.frame.size.height - kFeedbackButtonWidth;
            }
            rotationAngle = M_PI / 2;
        }
    }
    else
    {
        if (currentOrientation == UIDeviceOrientationPortraitUpsideDown)
        {
            if (self.feedbackButtonPosition == kFeedbackButtonPositionBottomRight)
            {
                x = kFeedbackButtonRightMargin;
                y = 0;
            }
            else
            {
                x = 0;
                y = kFeedbackButtonBottomMargin;
            }
            rotationAngle = M_PI;
        }
        else
        {
            if (self.feedbackButtonPosition == kFeedbackButtonPositionBottomRight)
            {
                x = windowView.frame.size.width - kFeedbackButtonWidth - kFeedbackButtonRightMargin;
                y = windowView.frame.size.height - kFeedbackButtonHeight;
            }
            else
            {
                x = windowView.frame.size.width - kFeedbackButtonWidth;
                y = windowView.frame.size.height - kFeedbackButtonBottomMargin - kFeedbackButtonHeight;
            }
            rotationAngle = 0;
        }
    }
    
    // apply new frame and rotation :
    CGRect feedbackButtonFrame = CGRectMake(x, y, kFeedbackButtonWidth, kFeedbackButtonHeight);
    self.feedbackButton.transform = CGAffineTransformIdentity;
    self.feedbackButton.frame = feedbackButtonFrame;
    self.feedbackButton.transform = CGAffineTransformMakeRotation(rotationAngle);
    
    if (shouldShowButton)
    {
        // show button :
        [UIView animateWithDuration:kAnimationDuration animations:^{
            [self.feedbackButton setAlpha:1];
        }];
    }
}


@end
