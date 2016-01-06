//
//  SWBUserKeyController.m
//  shadowsocks
//
//  Created by simon xu on 3/9/16.
//  Copyright © 2016 clowwindy. All rights reserved.
//

#import <openssl/evp.h>
#import <QuartzCore/QuartzCore.h>
#import "LoginController.h"
#import "ShadowsocksRunner.h"
#import "ProfileManager.h"
#import "encrypt.h"
#import "HttpUtil.h"
#import "Util.h"
#import "User.h"
#import "SWBAppDelegate.h"


@implementation LoginController {
    Configuration *configuration;
}

- (void)windowWillLoad {
    [super windowWillLoad];
}

- (void)windowDidLoad
{
    //设置Label  _L(Email / Mobile)
    [_UsernameLabel setStringValue:_L(Email / Mobile)];
    [_PasswordLabel setStringValue:_L(Password)];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle new] init ];
    paragraphStyle.alignment = NSTextAlignmentRight;
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:_L(Signup)];
    [attributeString addAttribute:NSUnderlineStyleAttributeName
                            value:[NSNumber numberWithInt:1]
                            range:(NSRange){0,[attributeString length]}];
    [attributeString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:(NSRange){0,[attributeString length]}];
    _SignupLabel.attributedStringValue = [attributeString copy];
    
    attributeString = [[NSMutableAttributedString alloc] initWithString:_L(Find Password)];
    [attributeString addAttribute:NSUnderlineStyleAttributeName
                            value:[NSNumber numberWithInt:1]
                            range:(NSRange){0,[attributeString length]}];
    [attributeString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:(NSRange){0,[attributeString length]}];
    _FindPasswordLabel.attributedStringValue = [attributeString copy];
    self.LoginTitle.stringValue = _L(Login);
    self.TitleLabel.stringValue = _L(RALLETS);
    
    //设置背景图
    NSImage* image = [NSImage imageNamed:@"LoginBackground.jpg"];
    [[self LoginView] layer].contents = image;

    //设置登录按钮

    CALayer *layer = self.LoginButton.layer;
    layer.backgroundColor = [[NSColor clearColor] CGColor];
    layer.borderColor = [[NSColor lightGrayColor] CGColor];
    layer.cornerRadius = 4.0f;
    layer.borderWidth = 2.0f;
    
    //设置注册和找回密码按钮
    self.SignupLabel.textColor = [NSColor whiteColor];
    CALayer *signupButtonLayer = self.SignupButton.layer;
    signupButtonLayer.backgroundColor = [[NSColor clearColor] CGColor];
    signupButtonLayer.borderColor = [[NSColor lightGrayColor] CGColor];
    signupButtonLayer.borderWidth = 0.0f;
    
    self.FindPasswordLabel.textColor = [NSColor whiteColor];
    CALayer *findPasswordLabelLayer = self.FindPasswordLabel.layer;
    findPasswordLabelLayer.backgroundColor = [[NSColor clearColor] CGColor];
    findPasswordLabelLayer.borderColor = [[NSColor lightGrayColor] CGColor];
    findPasswordLabelLayer.borderWidth = 0.0f;
    
    [self.TitleLabel sizeToFit];
    
    // 自动填写上次用户名和密码
    [_UsernameTF setStringValue:[User one].email];
    [_PasswordSTF setStringValue:[User one].password];
}

- (IBAction)onSignup:(id)sender {
    [Util openUrl:@"http://account.rallets.com/#/signup"];
}
- (IBAction)onFindPassword:(id)sender {
    [Util openUrl:@"http://account.rallets.com/#/find_password"];
}

- (IBAction)onLogin:(id)sender {
    SWBAppDelegate* appDelegate = [SWBAppDelegate one];
    [User one].email = [self.UsernameTF stringValue];
    [User one].password = [self.PasswordSTF stringValue];
    NSDictionary* result = [HttpUtil login:[self.UsernameTF stringValue] password:[self.PasswordSTF stringValue]];
    if (result != nil) {
        if ([result[@"ok"] boolValue]) {
            NSLog(@"Successfully Logged In");
            [User one].sessionId = result[@"session_id"];
            [appDelegate closeLoginForm];
            [appDelegate setRunning:YES];
            [appDelegate ralletsNotification];
        } else {
            NSLog(@"Failed Logged In");
            [User one].sessionId = @"";
            [self showWarningTitle:result[@"message"]];
        }
    }
}

- (void) showWarningTitle:(NSString*)title {
    if (!title) title = @"";
    [self.NotifyLabel setStringValue:title];
    [self.NotifyLabel setTextColor:[Util colorFromHexString:@"21CAA4"]];
}

- (void) showTitle:(NSString*)title {
    if (!title) title = @"";
    [self.NotifyLabel setStringValue:title];
    [self.NotifyLabel setTextColor:NSColor.whiteColor];
}
@end
