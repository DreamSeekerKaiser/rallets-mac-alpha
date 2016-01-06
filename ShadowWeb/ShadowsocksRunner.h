//
// Created by clowwindy on 14-2-27.
// Copyright (c) 2014 clowwindy. All rights reserved.
//

#import <Foundation/Foundation.h>


#define kRalletsIPKey @"proxy ip"
#define kRalletsPortKey @"proxy port"
#define kRalletsPasswordKey @"proxy password"
#define kRalletsEncryptionKey @"proxy encryption"
#define kRalletsProxyModeKey @"proxy mode"
#define kRalletsUsePublicServer @"public server"


@interface ShadowsocksRunner : NSObject

+ (BOOL)settingsAreNotComplete;
+ (BOOL)runProxy;
+ (void)reloadConfig;
+ (BOOL)openSSURL:(NSURL *)url;
+ (NSURL *)generateSSURL;
+ (NSString *)configForKey:(NSString *)key;
+ (void)saveConfigForKey:(NSString *)key value:(NSString *)value;
+ (void)setUsingPublicServer:(BOOL)use;
+ (BOOL)isUsingPublicServer;


@end
