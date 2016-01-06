//
// Created by clowwindy on 11/3/14.
// Copyright (c) 2014 clowwindy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Configuration.h"

@interface ProfileManager : NSObject

+ (Configuration *)configuration;
+ (void)saveConfiguration:(Configuration *)configuration;
+ (BOOL) setConfigsIfDifferent:(NSArray*)serverConfigs;
+ (void)clearConfigs;
+ (void)reloadShadowsocksRunner;
+ (NSData*)updateConfigurationFromUrl:(NSString*)url;
+ (NSData*) decryptConfiguration: (NSString*) crypted_data;

@property (strong, nonatomic) NSString *ralletsServer;

@end
