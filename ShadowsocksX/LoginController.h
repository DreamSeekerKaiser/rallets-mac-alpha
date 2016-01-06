//
//  SWBUserKeyController.h
//  shadowsocks
//
//  Created by simon xu on 3/9/16.
//  Copyright © 2016 clowwindy. All rights reserved.
//

#ifndef SWBUserKeyController_h
#define SWBUserKeyController_h
#import <Cocoa/Cocoa.h>
#import "Util.h"

@protocol SWBUserKeyControllerDelegate <NSObject>

@optional
- (void)configurationDidChange;

@end

@interface LoginController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTextField *UsernameLabel;
@property (weak) IBOutlet NSTextField *PasswordLabel;

@property (weak) IBOutlet NSTextField *TitleLabel;

@property (weak) IBOutlet NSTextField *LoginTitle;
@property (weak) IBOutlet NSButton *LoginButton;

@property (weak) IBOutlet NSTextField *SignupLabel;
@property (weak) IBOutlet NSView *SignupButton;

@property (weak) IBOutlet NSImageView *Logo;
@property (weak) IBOutlet NSTextField *FindPasswordLabel;

@property (weak) IBOutlet NSTextField *UsernameTF;
@property (weak) IBOutlet NSSecureTextField *PasswordSTF;
@property (weak) IBOutlet NSTextField *NotifyLabel;

@property (nonatomic, weak) id<SWBUserKeyControllerDelegate> delegate;
@property (strong) IBOutlet NSWindow *windows;

@property (weak) IBOutlet NSView *LoginView;
- (void) showWarningTitle:(NSString*)title;
- (void) showTitle:(NSString*)title;
@end

#endif /* SWBUserKeyController_h */
