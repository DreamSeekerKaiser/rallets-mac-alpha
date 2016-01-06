//
// Created by clowwindy on 11/3/14.
// Copyright (c) 2014 clowwindy. All rights reserved.
//

#import "ProfileManager.h"
#import "ShadowsocksRunner.h"
#import "openssl/rc4.h"
#import "openssl/evp.h"
#import "openssl/md5.h"
#import "HttpUtil.h"
#import "SWBAppDelegate.h"


#define CONFIG_DATA_KEY @"rallets_config"
@implementation ProfileManager {
}

static Configuration* _configuration = nil;
static NSArray* currentServerConfigs = nil;

+ (Configuration *)configuration {
    if (_configuration == nil) {
        _configuration = [Configuration alloc];
        NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:CONFIG_DATA_KEY];
        if (!data) data =[[NSData alloc] init];
        NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        if (!dict) dict =[[NSDictionary alloc] init];
        [_configuration initWithJSONData:dict];
    }
    return _configuration;
}

+ (void)setConfiguration: (Configuration*) c {
    _configuration = c;
}

+ (void)clearConfigs {
    currentServerConfigs = [NSArray array];
    [[ProfileManager configuration] clearConfigs];
}

+ (BOOL)setConfigsIfDifferent:(NSArray*)serverConfigs {
    if ([[currentServerConfigs componentsJoinedByString: @","] isEqualToString:[serverConfigs componentsJoinedByString: @","]]) return false;
    currentServerConfigs = serverConfigs;
    Configuration* config = [self configuration];
    [config setConfigs:currentServerConfigs];
    [self saveConfiguration:config];
    [[SWBAppDelegate one] updateMenu];
    return true;
}

+ (void)saveConfiguration:(Configuration *)configuration {
    if (configuration.profiles.count > 0) {
        if (configuration.current < 0 || configuration.current >= (int)configuration.profiles.count) {
            configuration.current = 0;
        }
    } else {
        configuration.current = -1;
    }
    [[NSUserDefaults standardUserDefaults] setObject:[configuration JSONData] forKey:CONFIG_DATA_KEY];
    [ProfileManager reloadShadowsocksRunner];
}

+ (void)connection:(NSURLConnection *)connection didReceiveData:(NSData*)data {
    NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

+ (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Finish with error");
}

+ (void)reloadShadowsocksRunner {
    Configuration *configuration = [ProfileManager configuration];
    if (configuration.current == -1) {
        [ShadowsocksRunner setUsingPublicServer:YES];
        [ShadowsocksRunner reloadConfig];
    } else {
        Profile *profile = configuration.profiles[configuration.current];
        [ShadowsocksRunner setUsingPublicServer:NO];
        [ShadowsocksRunner saveConfigForKey:kRalletsIPKey value:profile.server];
        [ShadowsocksRunner saveConfigForKey:kRalletsPortKey value:[NSString stringWithFormat:@"%ld", (long)profile.serverPort]];
        [ShadowsocksRunner saveConfigForKey:kRalletsPasswordKey value:profile.password];
        [ShadowsocksRunner saveConfigForKey:kRalletsEncryptionKey value:profile.method];
        [ShadowsocksRunner reloadConfig];
    }
}
@end
