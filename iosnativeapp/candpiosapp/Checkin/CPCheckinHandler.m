//
//  CPCheckinHandler.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/26/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPCheckinHandler.h"

@implementation CPCheckinHandler

+ (void)handleSuccessfulCheckinToVenue:(CPVenue *)venue checkoutTime:(NSInteger)checkoutTime checkinType:(CPCheckinType)checkinType
{       
    [CPAppDelegate setCheckedOut];
    // set the NSUserDefault to the user checkout time
    [CPUserDefaultsHandler setCheckoutTime:checkoutTime];
    
    // Save current place to venue defaults as it's used in several places in the app
    [CPUserDefaultsHandler setCurrentVenue:venue];
    
    BOOL forcedCheckin = (checkinType == CPCheckinTypeForced);
    
    // Add this venue to the list of recent venues for the feed TVC
    // if this was a forced checkin we need to show the feed now
    [CPUserDefaultsHandler addFeedVenue:venue showFeedNow:forcedCheckin];
    
    if (forcedCheckin) {
        // this was a forced checkin
        // so use the IBAction on the tabBarController to post to the feed
        [[CPAppDelegate tabBarController] postUpdateButtonPressed:nil];
    }
    
    // If this is the user's first check in to this venue and auto-checkins are enabled,
    // ask the user about checking in automatically to this venue in the future
    BOOL automaticCheckins = [CPUserDefaultsHandler automaticCheckins];
    
    if (automaticCheckins) {
        // Only show the alert if the current venue isn't currently in the list of monitored venues
        CPVenue *matchedVenue = [CPAppDelegate venueWithName:venue.name];
        
        if (!matchedVenue) {                    
            UIAlertView *autoCheckinAlert = [[UIAlertView alloc] initWithTitle:nil 
                                                                       message:@"Automatically check in to this venue in the future?" 
                                                                      delegate:[CPAppDelegate settingsMenuController]
                                                             cancelButtonTitle:@"No" 
                                                             otherButtonTitles:@"Yes", nil];
            autoCheckinAlert.tag = AUTOCHECKIN_PROMPT_TAG;
            [autoCheckinAlert show];
        }
    }
}

+ (void)queueLocalNotificationForVenue:(CPVenue *)venue checkoutTime:(NSInteger)checkoutTime
{
    // Fire a notification 5 minutes before checkout time
    NSInteger minutesBefore = 5;
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    NSDictionary *venueDataDict;
    
    // Cancel all old local notifications
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    localNotif.alertBody = @"You will be checked out of C&P in 5 min.";
    localNotif.alertAction = @"Check Out";
    localNotif.soundName = UILocalNotificationDefaultSoundName;
    
    localNotif.fireDate = [NSDate dateWithTimeIntervalSince1970:(checkoutTime - minutesBefore * 60)];
    localNotif.timeZone = [NSTimeZone defaultTimeZone];
    
    // encode the venue and store it in an NSDictionary
    NSData *venueData = [NSKeyedArchiver archivedDataWithRootObject:venue];
    venueDataDict = [NSDictionary dictionaryWithObject:venueData forKey:@"venue"];
    
    localNotif.userInfo = venueDataDict;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
}

@end
