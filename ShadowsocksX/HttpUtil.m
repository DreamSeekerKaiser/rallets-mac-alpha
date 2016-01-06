//
//  HttpUtil.m
//  shadowsocks
//
//  Created by Jie Feng on 5/7/16.
//  Copyright © 2016 clowwindy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpUtil.h"
#import "ProfileManager.h"
#import "LoginController.h"
#import "SWBAppDelegate.h"
#import "Util.h"
#import "AESCrypt.h"
#import "User.h"
#define NSLog(FORMAT, ...) printf("%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

@interface NSURLRequest (DummyInterface)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@implementation HttpUtil: NSObject {
}

static NSString* DEFAULT_SERVER_ROOT = @"https://rallets.com/";
+ (NSString *)serverRoot {
    static NSString* _serverRoot = nil;
    
    if (_serverRoot == nil) {
        // 如果不前设置为Default, 回访时会出现死循环
        _serverRoot = DEFAULT_SERVER_ROOT;
        if(![[self getText:@"ping" params:@""]  isEqual: @"pong"]) {
            NSArray *ralletsServerLookupUrls = @[@"http://git.oschina.net/rallets/rallets/raw/master/EncryptedConfig", @"http://raw.githubusercontent.com/ralletstellar/rallets/master/EncryptedConfig"];
            for (NSString* lookupUrl in ralletsServerLookupUrls) {
                NSURLResponse* response = nil;
                NSError *error = nil;
                NSURLRequest* request=[NSURLRequest requestWithURL:[NSURL URLWithString:lookupUrl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:6.0];
                NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                if (data == nil) {
                    NSLog(@"Error: serverRoot - Requesting Rallets server lookup urls (most possibly timeout)");
                } else {
                    NSCharacterSet *whitespace = [NSCharacterSet  whitespaceAndNewlineCharacterSet];
                    NSString* base64EncodedServerUrl = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
                                                        stringByTrimmingCharactersInSet:whitespace];
                    NSData* decodedData = [[NSData alloc]
                                           initWithBase64EncodedString:base64EncodedServerUrl
                                           options:0];
                    _serverRoot = [[[NSString alloc]
                                   initWithData:decodedData
                                   encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:whitespace];
                    break;
                }
            }
        }
        // 如果获取资源全部失败，启用默认rallets.com
        if (_serverRoot == nil) _serverRoot = DEFAULT_SERVER_ROOT;
    }
    return _serverRoot;
}
+ (NSString *) url:(NSString *)relativeUrl {
    return [HttpUtil.serverRoot stringByAppendingString:relativeUrl];
}
+ (NSMutableURLRequest *) makeRequest:(NSString*)relativeUrl params:(NSMutableDictionary*)params {
    if (params == nil) {
        params = [[NSMutableDictionary alloc] init];
    }
    [params setObject:@"MAC" forKey:@"DEVICE_TYPE"];
    [params setObject:[Util currentVersion] forKey:@"VERSION"];
    [params setObject:[User one].sessionId forKey:@"session_id"];
    NSData *postData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    NSURL *host = [NSURL URLWithString:[HttpUtil url:relativeUrl]];
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:host];
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[host host]];
    [postRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [postRequest setHTTPMethod:@"POST"];
    [postRequest setHTTPBody:postData];
    return postRequest;
}
+ (NSString*) getText:(NSString*)relativeUrl params:(NSString*)params {
    NSURL* host = [NSURL URLWithString:[HttpUtil url:relativeUrl]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:host];
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[host host]];
    [request setHTTPMethod:@"GET"];
    NSURLResponse* response = nil;
    NSError *error = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error) {
        NSLog(@"Error: getText");
        return nil;
    } else {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
}
+ (NSDictionary*) post:(NSString*)relativeUrl params:(NSMutableDictionary*)params {
    NSMutableURLRequest *postRequest = [HttpUtil makeRequest:relativeUrl params:params];
    NSURLResponse* response = nil;
    NSError *error = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:postRequest returningResponse:&response error:&error];
    if (error) return nil;
    NSDictionary* ret = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (error) return nil;
    return ret;
}

+ (NSDictionary*) login:(NSString*)username password:(NSString*)password{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                         username, @"username_or_email",
                         password, @"login_password",
                         nil];
    return [HttpUtil post:@"login" params:params];
}
+ (void)connection:(NSURLConnection *)connection didReceiveData:(NSData*)data {
    NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}
+ (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Post connection results error");
}
+ (void) processRalletsNotificationData:(NSMutableDictionary *)data {
    if (data == nil) return;
    SWBAppDelegate* app = [SWBAppDelegate one];
#ifdef DEBUG
    NSLog(@"%@", data);
#endif
    [User one].ralletsNotification = data;
    if ([data[@"ok"] boolValue]) {
        [ProfileManager setConfigsIfDifferent:data[@"self"][@"ssconfigs"]];
        NSDictionary* systemNotification = data[@"systemNotification"];
        if (!systemNotification) return;
        if ([Util isRemoteVersionNewer:systemNotification[@"version"]]) {
            NSAlert* alert = [app sysNotifictaionAlert:@"立即下载" informativeText:[NSString stringWithFormat:@"Rallets Mac有最新版本V%@可以更新", systemNotification[@"version"]]];
            NSModalResponse responseTag = [alert runModal];
            
            if (responseTag == NSAlertFirstButtonReturn) {
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:systemNotification[@"download_link"]]];
            }
        }
        if (systemNotification && [systemNotification[@"show"] boolValue]) {
            NSAlert* alert = [app sysNotifictaionAlert:@"Go" informativeText:systemNotification[@"message"]];
            NSModalResponse responseTag = [alert runModal];
            if (responseTag == NSAlertFirstButtonReturn) {
                NSURL* url = [NSURL URLWithString:systemNotification[@"link"]];
                if (url && url.scheme && url.host) {
                    [[NSWorkspace sharedWorkspace] openURL:url];
                }
            }
        }
    } else {
        [app logout:data[@"message"]];
    }
}
+ (void) postRalletsNotification {
    [self processRalletsNotificationData:[self post:@"rallets_notification" params:nil]];
}
@end
