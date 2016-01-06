//
//  SWBAppDelegate.h
//  ShadowsocksX
//
//  Created by clowwindy on 14-2-19.
//  Copyright (c) 2014年 clowwindy. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SWBAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, strong) NSStatusItem* item;
@property (nonatomic, strong) NSAlert* sysNotifictaionAlert;
- (void)toggleSystemProxy:(BOOL)useProxy;
- (void)updateMenu;
- (void)setRunning:(BOOL)isRunning;
- (void)ralletsNotification;
+ (SWBAppDelegate*) one;
- (NSAlert*) sysNotifictaionAlert:(NSString*)primaryText informativeText:(NSString*)informativeText;
- (void) logout:(NSString*) message;
- (void) closeLoginForm;
- (void) updateAccountItems;
@property (nonatomic, readonly) NSString *runningMode;
@property (nonatomic, retain) NSMutableData *receivedData; // For buffering data of async NSMutableURLRequest
@end
