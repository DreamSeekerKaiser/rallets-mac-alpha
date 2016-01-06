//
//  User.m
//  shadowsocks
//
//  Created by Jie Feng on 6/29/16.
//  Copyright © 2016 clowwindy. All rights reserved.
//

#import "User.h"
#import "Util.h"
#import "SWBAppDelegate.h"

@implementation User

static NSString* ACCOUNT_HOST = @"http://account.rallets.com/#/";

+ (User*) one {
    static User *user = nil;
    @synchronized(self) {
        if (user == nil)
            user = [[self alloc] init];
    }
    return user;
}


- (id)init {
    return self;
}

- (void) logout {
    self.sessionId = @"";
}

@synthesize sessionId = _sessionId;
- (NSString*) sessionId {
    if (!_sessionId) {
        _sessionId = [[NSUserDefaults standardUserDefaults] objectForKey:@"rallets_session_id"];
    }
    if (_sessionId == nil) {
        _sessionId = @"";
    }
    return _sessionId;
}

- (void) setSessionId:(NSString *)v {
    [[NSUserDefaults standardUserDefaults] setObject:v forKey:@"rallets_session_id"];
    _sessionId = v;
}

@synthesize email = _email;
- (NSString*) email {
    if (!_email) {
        _email = [[NSUserDefaults standardUserDefaults] objectForKey:@"rallets_email"];
    }
    return _email ? _email : @"";
}

- (void) setEmail:(NSString*)v {
    [[NSUserDefaults standardUserDefaults] setObject:v forKey:@"rallets_email"];
    _email = v;
}

@synthesize password = _password;
- (NSString*) password {
    if (!_password) {
        _password = [[NSUserDefaults standardUserDefaults] objectForKey:@"rallets_password"];
    }
    return _password ? _password : @"";
}
- (void) setPassword:(NSString*)password {
    [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"rallets_password"];
    _password = password;
}

@synthesize ralletsNotification = _ralletsNotification;
- (NSDictionary*) ralletsNotification {
    return _ralletsNotification;
}
- (void) setRalletsNotification:(NSDictionary*)v {
    _ralletsNotification = v;
    SWBAppDelegate* app = [SWBAppDelegate one];
    [app updateAccountItems];
}

- (BOOL)loggedIn {
    return !(self.sessionId == nil || [self.sessionId length] == 0);
}
static float GB = 1073741824;

- (float)premiumTraffic {
    return ([self.ralletsNotification[@"self"][@"traffic"][@"premium"] floatValue])/ GB;
}

- (float)basicTraffic {
    return ([self.ralletsNotification[@"self"][@"traffic"][@"basic"] floatValue])/ GB;
}
- (NSString *)remainingTime {
    if (self.ralletsNotification == nil) return @"0";
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZZ"];
    NSDate *endDate = [formatter dateFromString:self.ralletsNotification[@"self"][@"end_time"]];
    if (endDate == nil) return @"";
    NSDate *now = [NSDate date];
    NSTimeInterval secondsBetween = [endDate timeIntervalSinceDate:now];
    int nHours = secondsBetween / 3600;
    return [NSString stringWithFormat:@"%d%@ %d%@", nHours / 24, _L(Day), nHours % 24, _L(Hour)];
}
- (void)openAccountPageWithAutoLogin:(NSString *)rUrl {
    NSString* url = [NSString stringWithFormat:@"%@%@?username_or_email=%@&login_password=%@", ACCOUNT_HOST, rUrl, [Util base64Encode:self.email], [Util base64Encode:self.password]];
    [Util openUrl:url];
}
@end
