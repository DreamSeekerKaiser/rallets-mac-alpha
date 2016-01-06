//
//  User.h
//  shadowsocks
//
//  Created by Jie Feng on 6/29/16.
//  Copyright © 2016 clowwindy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

+ (User*) one;

@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, readonly) BOOL loggedIn;
@property (nonatomic, retain) NSString* sessionId;
@property (nonatomic, retain) NSDictionary* ralletsNotification;
- (float)premiumTraffic;
- (float)basicTraffic;
- (void) logout;
- (void)openAccountPageWithAutoLogin:(NSString *)rUrl;
- (NSString *)remainingTime;
@end
