//
//  Header.h
//  shadowsocks
//
//  Created by Jie Feng on 5/7/16.
//  Copyright © 2016 clowwindy. All rights reserved.
//

#ifndef Header_h
#define Header_h
#import "LoginController.h"
#import "SWBAppDelegate.h"
@interface HttpUtil : NSObject
+ (NSString *) serverRoot;
+ (NSString *) url: (NSString *)relativeUrl;
+ (NSMutableURLRequest *) makeRequest:(NSString*)relativeUrl params:(NSString*)params;
+ (NSDictionary*) post:(NSString*)relativeUrl params:(NSString*)params;
+ (NSDictionary*) login:(NSString*)username password:(NSString*)password;
+ (void) processRalletsNotificationData:(NSDictionary *)data;
+ (void) postRalletsNotification;
@end
#endif /* Header_h */
